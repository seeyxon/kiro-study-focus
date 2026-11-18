//
//  ContentView.swift
//  StudyFocus
//
//  Created by 안시연 on 11/18/26.
//

import Charts
import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: StudyFocusModel

    var body: some View {
        TabView {
            FocusView(model: model)
                .tabItem {
                    Label("집중", systemImage: "timer")
                }

            StatisticsView(model: model)
                .tabItem {
                    Label("통계", systemImage: "chart.bar")
                }
        }
        .sheet(isPresented: completionPresentation) {
            CompletionView(model: model)
        }
    }

    private var completionPresentation: Binding<Bool> {
        Binding(
            get: { model.isCompletionPresented },
            set: { isPresented in
                if !isPresented {
                    model.dismissCompletion()
                }
            }
        )
    }
}

private enum LattePalette {
    static let background = Color(red: 248 / 255, green: 244 / 255, blue: 238 / 255)
    static let cream = Color(red: 233 / 255, green: 220 / 255, blue: 203 / 255)
    static let darkBrown = Color(red: 107 / 255, green: 79 / 255, blue: 59 / 255)
    static let orange = Color(red: 232 / 255, green: 138 / 255, blue: 67 / 255)
    static let nearWhite = Color(red: 255 / 255, green: 254 / 255, blue: 251 / 255)
    static let dashboardBackground = Color(red: 49 / 255, green: 34 / 255, blue: 27 / 255)
    static let dashboardCard = Color(red: 72 / 255, green: 50 / 255, blue: 39 / 255)
    static let dashboardCardRaised = Color(red: 87 / 255, green: 60 / 255, blue: 45 / 255)
}

private struct LatteCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LattePalette.nearWhite)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LattePalette.cream.opacity(0.7), lineWidth: 1)
            }
    }
}

private struct FocusView: View {
    @ObservedObject var model: StudyFocusModel

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let activeSession = model.activeSession {
                        activeSessionView(activeSession)
                    } else {
                        sessionStartView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(LattePalette.background.ignoresSafeArea())
            .foregroundStyle(LattePalette.darkBrown)
            .navigationTitle("집중 학습")
            .toolbarBackground(LattePalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(LattePalette.orange)
    }

    private var sessionStartView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(LattePalette.orange)
                    .accessibilityHidden(true)

                Text("집중을 시작해요")
                    .font(.title2.bold())

                Text("세션 이름을 정하고 준비되면 시작하세요.")
                    .font(.body)
                    .foregroundStyle(LattePalette.darkBrown.opacity(0.72))
            }

            LatteCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("무엇에 집중할까요?", systemImage: "pencil.line")
                        .font(.headline)

                    TextField("세션 제목", text: $model.sessionTitleDraft)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(LattePalette.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LattePalette.cream, lineWidth: 1)
                        }
                        .submitLabel(.go)
                        .onSubmit {
                            if model.canStartSession {
                                model.startSession()
                            }
                        }

                    Button {
                        model.startSession()
                    } label: {
                        Label("집중 시작", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(LattePalette.nearWhite)
                    .background(LattePalette.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(!model.canStartSession)
                    .opacity(model.canStartSession ? 1 : 0.45)
                }
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    private func activeSessionView(_ activeSession: ActiveSession) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            LatteCard {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(LattePalette.orange)
                        .frame(width: 44, height: 44)
                        .background(LattePalette.cream.opacity(0.65))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("진행 중인 세션")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(LattePalette.darkBrown.opacity(0.68))

                        Text(activeSession.title)
                            .font(.title2.bold())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            TimelineView(.periodic(from: activeSession.startDate, by: 1)) { context in
                let elapsedSeconds = StudyFocusModel.elapsedSeconds(
                    from: activeSession.startDate,
                    to: context.date
                )

                LatteCard {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("경과 시간")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(LattePalette.darkBrown.opacity(0.68))

                            Text(formatDuration(elapsedSeconds))
                                .font(.system(size: 46, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                                .monospacedDigit()
                                .accessibilityLabel("경과 시간, \(elapsedSeconds)초")
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .overlay(LattePalette.cream)

                        PomodoroStatusView(
                            state: StudyFocusModel.pomodoroState(
                                from: activeSession.startDate,
                                to: context.date
                            )
                        )
                    }
                }
            }

            Button(role: .destructive) {
                model.requestSessionEnd()
            } label: {
                Label("집중 종료", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(LattePalette.nearWhite)
            .background(LattePalette.orange)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: 560, alignment: .leading)
        .frame(maxWidth: .infinity)
    }
}

private struct PomodoroStatusView: View {
    let state: PomodoroState

    var body: some View {
        VStack(spacing: 8) {
            Label("뽀모도로 데모", systemImage: "timer")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LattePalette.darkBrown.opacity(0.68))

            switch state {
            case .remaining(let seconds):
                Text("\(seconds)")
                    .font(.title.bold())
                    .monospacedDigit()
                    .accessibilityLabel("뽀모도로, \(seconds)초 남음")
            case .complete:
                Label("완료", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(LattePalette.orange)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CompletionView: View {
    @ObservedObject var model: StudyFocusModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("세션 세부 정보")
                            .font(.title2.bold())

                        Text("이 세션을 기억하는 데 도움이 되도록 과목이나 메모를 추가하세요.")
                            .font(.body)
                            .foregroundStyle(LattePalette.darkBrown.opacity(0.72))
                    }

                    LatteCard {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("과목", systemImage: "tag")
                                    .font(.headline)

                                TextField("과목(선택)", text: $model.completionSubjectDraft)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 52)
                                    .background(LattePalette.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Label("메모", systemImage: "note.text")
                                    .font(.headline)

                                TextField(
                                    "메모(선택)",
                                    text: $model.completionMemoDraft,
                                    axis: .vertical
                                )
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(16)
                                .frame(minHeight: 112, alignment: .topLeading)
                                .background(LattePalette.background)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }

                    if let errorMessage = model.completionErrorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LattePalette.nearWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityLabel("저장 오류: \(errorMessage)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(LattePalette.background.ignoresSafeArea())
            .foregroundStyle(LattePalette.darkBrown)
            .navigationTitle("세션 완료")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LattePalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .interactiveDismissDisabled(false)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        model.dismissCompletion()
                    }
                    .foregroundStyle(LattePalette.darkBrown)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        model.confirmCompletion()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(LattePalette.orange)
                }
            }
        }
        .tint(LattePalette.orange)
    }
}

private struct StatisticsView: View {
    @ObservedObject var model: StudyFocusModel

    var body: some View {
        let records = model.records
        let subjectTotals = StudyFocusModel.subjectTotals(in: records)
        let dailyTotals = StudyFocusModel.dailyTotals(
            in: records,
            calendar: .current
        )
        let coachingMessage = StudyFocusModel.coachingMessage(
            records: records,
            now: Date(),
            calendar: .current
        )

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if records.isEmpty {
                        emptyStatisticsCard
                    } else {
                        statisticsContent(
                            records: records,
                            subjectTotals: subjectTotals,
                            dailyTotals: dailyTotals
                        )
                    }

                    coachingCard(message: coachingMessage)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(LattePalette.dashboardBackground.ignoresSafeArea())
            .foregroundStyle(LattePalette.cream)
            .navigationTitle("통계")
            .toolbarBackground(LattePalette.dashboardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(LattePalette.dashboardBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
        }
        .tint(LattePalette.orange)
    }

    private var emptyStatisticsCard: some View {
        StatisticsCard {
            VStack(spacing: 14) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(LattePalette.orange)
                    .accessibilityHidden(true)

                Text("완료한 집중 세션 없음")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text("아직 완료한 집중 세션이 없습니다.")
                    .font(.body)
                    .foregroundStyle(LattePalette.cream.opacity(0.76))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private func statisticsContent(
        records: [FocusRecord],
        subjectTotals: [SubjectTotal],
        dailyTotals: [DailyTotal]
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            StatisticsCard(emphasized: true) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("총 집중 시간", systemImage: "timer")
                        .font(.headline)
                        .foregroundStyle(LattePalette.cream.opacity(0.78))

                    Text(formatDuration(StudyFocusModel.totalDuration(in: records)))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(LattePalette.nearWhite)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .accessibilityLabel("총 집중 시간")
                        .accessibilityValue(
                            formatDuration(StudyFocusModel.totalDuration(in: records))
                        )
                }
            }

            StatisticsCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label("일별 집중 시간", systemImage: "chart.bar.fill")
                        .font(.title3.bold())

                    Chart(dailyTotals) { total in
                        BarMark(
                            x: .value("날짜", total.day, unit: .day),
                            y: .value("집중 시간(초)", total.seconds)
                        )
                        .foregroundStyle(LattePalette.orange)
                        .accessibilityLabel(
                            total.day.formatted(date: .abbreviated, time: .omitted)
                        )
                        .accessibilityValue(formatDuration(total.seconds))
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine()
                                .foregroundStyle(LattePalette.cream.opacity(0.12))
                            AxisTick()
                                .foregroundStyle(LattePalette.cream.opacity(0.45))
                            AxisValueLabel()
                                .foregroundStyle(LattePalette.cream.opacity(0.78))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                            AxisGridLine()
                                .foregroundStyle(LattePalette.cream.opacity(0.16))
                            AxisTick()
                                .foregroundStyle(LattePalette.cream.opacity(0.45))
                            AxisValueLabel()
                                .foregroundStyle(LattePalette.cream.opacity(0.78))
                        }
                    }
                    .frame(height: 240)
                }
            }

            StatisticsCard {
                VStack(alignment: .leading, spacing: 18) {
                    Label("과목별", systemImage: "books.vertical.fill")
                        .font(.title3.bold())

                    let largestSubjectTotal = max(
                        subjectTotals.map(\.seconds).max() ?? 0,
                        1
                    )

                    ForEach(subjectTotals) { total in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(total.subject)
                                    .font(.body.weight(.semibold))
                                    .lineLimit(2)

                                Spacer(minLength: 12)

                                Text(formatDuration(total.seconds))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(LattePalette.cream.opacity(0.82))
                                    .monospacedDigit()
                            }

                            ProgressView(
                                value: Double(total.seconds),
                                total: Double(largestSubjectTotal)
                            )
                            .tint(LattePalette.orange)
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(total.subject)
                        .accessibilityValue(formatDuration(total.seconds))
                    }
                }
            }
        }
    }

    private func coachingCard(message: String) -> some View {
        StatisticsCard(emphasized: true) {
            VStack(alignment: .leading, spacing: 12) {
                Label("집중 코칭", systemImage: "lightbulb.fill")
                    .font(.title3.bold())
                    .foregroundStyle(LattePalette.orange)

                Text(message)
                    .font(.body)
                    .foregroundStyle(LattePalette.nearWhite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StatisticsCard<Content: View>: View {
    let emphasized: Bool
    let content: Content

    init(
        emphasized: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.emphasized = emphasized
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                emphasized
                    ? LattePalette.dashboardCardRaised
                    : LattePalette.dashboardCard
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LattePalette.cream.opacity(0.1), lineWidth: 1)
            }
    }
}

private func formatDuration(_ totalSeconds: Int) -> String {
    let hours = totalSeconds / 3_600
    let minutes = (totalSeconds % 3_600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

#Preview {
    ContentView(model: StudyFocusModel(defaults: UserDefaults(suiteName: "StudyFocusPreview")!))
}
