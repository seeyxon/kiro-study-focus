# Implementation Plan: Study Focus Hackathon MVP

## Overview

Extend the default SwiftUI starter with one shared `StudyFocusModel`, a Focus tab, and a Statistics tab. Build the smallest complete timestamp-driven flow first, then add persistence and derived statistics without introducing extra layers or out-of-scope features. Automated-test and generic test checkpoint tasks are omitted because automated tests are explicitly outside this 90-minute hackathon MVP.

## Tasks

- [x] 1. Build the session model and persistence logic
  - [x] 1.1 Create the domain types, observable state, and pure calculations
    - Add `StudyFocusModel.swift` with `ActiveSession`, `FocusRecord`, `PomodoroState`, `SubjectTotal`, and `DailyTotal`.
    - Define the model's published active-session, completion-draft, presentation, error, and record state.
    - Implement title and optional-field normalization, floored nonnegative timestamp duration, the 10-second Pomodoro state, total duration, subject grouping with `Uncategorized`, calendar-day grouping, and today's single-sentence coaching result.
    - Keep the active session in memory and keep all completed-record aggregates derived from the records array.
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 3.3, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4_

  - [x] 1.2 Implement session transitions and UserDefaults persistence
    - Implement guarded session start, end-sheet presentation and dismissal, and completion confirmation using one captured confirmation timestamp.
    - Encode the complete `[FocusRecord]` array as `Data` under `studyFocus.completedRecords.v1`, verify saved data before committing UI state, and preserve the active session and drafts with visible error state if saving fails.
    - Load records during model initialization, treating missing or malformed stored data as an empty collection.
    - Clear the active session and completion drafts only after a successful save so each confirmation contributes one record.
    - _Requirements: 1.1, 2.2, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 2. Build the SwiftUI experience and connect shared state
  - [x] 2.1 Replace the starter content with the Focus and completion flow
    - Update `ContentView.swift` to accept the shared model and present a two-destination `TabView` with Focus and Statistics destinations.
    - In the Focus destination, show the required title field and disabled Start control while its trimmed value is empty; after start, show the normalized title and an End control.
    - Use a one-second `TimelineView` redraw to display elapsed time and the 10-through-1 Pomodoro countdown from the unchanged session start timestamp, followed by a complete state.
    - Present a completion sheet with optional Subject and Memo inputs, save-failure feedback, cancel behavior that returns to the active session, and confirmation through the model.
    - _Requirements: 1.2, 1.3, 2.1, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.4_

  - [x] 2.2 Add completed-focus statistics and coaching
    - In `ContentView.swift`, implement the Statistics destination using only the model's derived totals.
    - Show the explicit no-records state when appropriate; otherwise show total focus time, sorted subject totals including `Uncategorized`, and a Swift Charts `BarMark` for each sorted represented calendar day.
    - Always render exactly one coaching `Text`, using the invitation for no records today or today's total-duration sentence when today's set is nonempty.
    - Keep duration formatting in the view layer and leave calculations as integer seconds.
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4_

  - [x] 2.3 Wire the model into the app entry point and complete build integration
    - Update `StudyFocusApp.swift` to own one `StudyFocusModel` with `@StateObject` and inject it into `ContentView`.
    - Adjust the SwiftUI preview to use an isolated model instance.
    - Resolve compile-time integration issues and confirm the existing iPhone app target builds without adding navigation, repository, recovery, lifecycle-tracking, or test infrastructure.
    - _Requirements: 1.1, 4.5, 4.6_

## Notes

- This plan is intentionally limited to the 90-minute hackathon MVP and the existing file-system-synchronized Xcode target.
- Automated tests and generic `Ensure all tests pass` checkpoints are omitted because tests are outside the agreed MVP scope.
- The final integration task includes a lightweight build check; manual demo verification remains described in `design.md` rather than as an implementation task.
- Do not add app-leave tracking, SwiftData or repository abstractions, notifications, audio, goals, streaks, export, or pending-result recovery.
- Each implementation task builds on the preceding state and leaves no standalone component unwired.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["2.1"] },
    { "id": 3, "tasks": ["2.2"] },
    { "id": 4, "tasks": ["2.3"] }
  ]
}
```
