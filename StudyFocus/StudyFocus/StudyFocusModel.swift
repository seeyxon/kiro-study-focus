//
//  StudyFocusModel.swift
//  StudyFocus
//

import Combine
import Foundation

struct ActiveSession: Equatable {
    let title: String
    let startDate: Date
}

struct FocusRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let durationSeconds: Int
    let subject: String?
    let memo: String?
}

enum PomodoroState: Equatable {
    case remaining(Int)
    case complete
}

struct SubjectTotal: Identifiable, Equatable {
    let subject: String
    let seconds: Int

    var id: String { subject }
}

struct DailyTotal: Identifiable, Equatable {
    let day: Date
    let seconds: Int

    var id: Date { day }
}

@MainActor
final class StudyFocusModel: ObservableObject {
    private enum PersistenceError: Error {
        case verificationFailed
    }

    private static let recordsKey = "studyFocus.completedRecords.v1"
    private static let saveFailureMessage =
        "이 집중 세션을 저장하지 못했습니다. 입력한 과목과 메모는 그대로 유지됩니다."

    @Published var sessionTitleDraft = ""
    @Published private(set) var activeSession: ActiveSession?
    @Published var completionSubjectDraft = ""
    @Published var completionMemoDraft = ""
    @Published private(set) var isCompletionPresented = false
    @Published private(set) var completionErrorMessage: String?
    @Published private(set) var records: [FocusRecord] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        guard let storedData = defaults.data(forKey: Self.recordsKey),
              let storedRecords = try? JSONDecoder().decode([FocusRecord].self, from: storedData) else {
            records = []
            return
        }

        records = storedRecords
    }

    var canStartSession: Bool {
        activeSession == nil && !Self.normalizeTitle(sessionTitleDraft).isEmpty
    }

    func startSession(now: Date = Date()) {
        guard activeSession == nil else { return }

        let normalizedTitle = Self.normalizeTitle(sessionTitleDraft)
        guard !normalizedTitle.isEmpty else { return }

        activeSession = ActiveSession(title: normalizedTitle, startDate: now)
    }

    func requestSessionEnd() {
        guard activeSession != nil else { return }

        completionErrorMessage = nil
        isCompletionPresented = true
    }

    func dismissCompletion() {
        guard isCompletionPresented else { return }

        isCompletionPresented = false
        completionErrorMessage = nil
    }

    func confirmCompletion(now: Date = Date()) {
        guard let activeSession else { return }

        let confirmationTime = now
        let record = FocusRecord(
            id: UUID(),
            title: activeSession.title,
            startDate: activeSession.startDate,
            endDate: confirmationTime,
            durationSeconds: Self.elapsedSeconds(
                from: activeSession.startDate,
                to: confirmationTime
            ),
            subject: Self.normalizeOptional(completionSubjectDraft),
            memo: Self.normalizeOptional(completionMemoDraft)
        )
        let candidateRecords = records + [record]

        do {
            try persist(candidateRecords)
        } catch {
            completionErrorMessage = Self.saveFailureMessage
            return
        }

        records = candidateRecords
        self.activeSession = nil
        completionSubjectDraft = ""
        completionMemoDraft = ""
        completionErrorMessage = nil
        isCompletionPresented = false
    }

    private func persist(_ candidateRecords: [FocusRecord]) throws {
        let encodedRecords = try JSONEncoder().encode(candidateRecords)
        let previousData = defaults.data(forKey: Self.recordsKey)

        defaults.set(encodedRecords, forKey: Self.recordsKey)

        do {
            guard let savedData = defaults.data(forKey: Self.recordsKey),
                  savedData == encodedRecords else {
                throw PersistenceError.verificationFailed
            }

            let decodedRecords = try JSONDecoder().decode(
                [FocusRecord].self,
                from: savedData
            )
            guard decodedRecords == candidateRecords else {
                throw PersistenceError.verificationFailed
            }
        } catch {
            if let previousData {
                defaults.set(previousData, forKey: Self.recordsKey)
            } else {
                defaults.removeObject(forKey: Self.recordsKey)
            }
            throw error
        }
    }

    static func normalizeTitle(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeOptional(_ value: String) -> String? {
        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedValue.isEmpty ? nil : normalizedValue
    }

    static func elapsedSeconds(from start: Date, to end: Date) -> Int {
        max(0, Int(floor(end.timeIntervalSince(start))))
    }

    static func pomodoroState(from start: Date, to now: Date) -> PomodoroState {
        let elapsed = elapsedSeconds(from: start, to: now)
        return elapsed < 10 ? .remaining(10 - elapsed) : .complete
    }

    static func totalDuration(in records: [FocusRecord]) -> Int {
        records.reduce(0) { total, record in
            total + record.durationSeconds
        }
    }

    static func subjectTotals(in records: [FocusRecord]) -> [SubjectTotal] {
        let totalsBySubject = records.reduce(into: [String: Int]()) { totals, record in
            let subject = record.subject ?? "미분류"
            totals[subject, default: 0] += record.durationSeconds
        }

        return totalsBySubject
            .map { SubjectTotal(subject: $0.key, seconds: $0.value) }
            .sorted { $0.subject < $1.subject }
    }

    static func dailyTotals(
        in records: [FocusRecord],
        calendar: Calendar
    ) -> [DailyTotal] {
        let totalsByDay = records.reduce(into: [Date: Int]()) { totals, record in
            let day = calendar.startOfDay(for: record.endDate)
            totals[day, default: 0] += record.durationSeconds
        }

        return totalsByDay
            .map { DailyTotal(day: $0.key, seconds: $0.value) }
            .sorted { $0.day < $1.day }
    }

    static func coachingMessage(
        records: [FocusRecord],
        now: Date,
        calendar: Calendar
    ) -> String {
        guard let today = calendar.dateInterval(of: .day, for: now) else {
            return "오늘 집중 세션을 시작하고 한 가지 일에 온전히 집중해 보세요."
        }

        let todayRecords = records.filter { today.contains($0.endDate) }
        guard !todayRecords.isEmpty else {
            return "오늘 집중 세션을 시작하고 한 가지 일에 온전히 집중해 보세요."
        }

        let todayTotal = totalDuration(in: todayRecords)
        let unit = todayTotal == 1 ? "초" : "초"
        return "오늘 \(todayTotal)\(unit) 동안 집중했으니 이 흐름을 계속 이어가세요."
    }
}
