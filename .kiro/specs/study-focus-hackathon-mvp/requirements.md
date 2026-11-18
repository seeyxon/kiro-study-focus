# Requirements Document

## Introduction

Study Focus Hackathon MVP is an iPhone SwiftUI demonstration that lets a learner name and start a focus session, view elapsed time calculated from timestamps, complete a 10-second Pomodoro demonstration interval, record an optional subject and memo when ending a session, and review focus statistics. The MVP persists records with UserDefaults and provides a single coaching sentence based on the current calendar day's records.

This specification excludes a SwiftData or repository layer, local notifications, background audio, goals, streaks, JSON export, automated tests, and pending-result recovery. Source requirements outside this stated MVP scope are reference material for later work only.

## Glossary

- **StudyFocus_App**: The iPhone SwiftUI application that provides the Study Focus Hackathon MVP.
- **Focus_Session**: A learner-initiated interval with a title and start timestamp that is active until the learner requests session end.
- **Session_Title**: The learner-entered label used to identify a Focus_Session before the Focus_Session begins.
- **Normalized_Session_Title**: A Session_Title with leading and trailing whitespace removed.
- **Processing_Time_Timestamp**: The device timestamp at which StudyFocus_App processes a learner request to start a Focus_Session.
- **Confirmation_Time_Timestamp**: The device timestamp at which StudyFocus_App processes a learner confirmation of completion details.
- **Focus_Record**: A completed Focus_Session saved with Session_Title, start timestamp, end timestamp, Elapsed_Focus_Duration, optional Subject, and optional Memo.
- **Elapsed_Focus_Duration**: The whole-second duration obtained by rounding down the non-negative difference between a Focus_Session start timestamp and the current timestamp or end timestamp.
- **Final_Elapsed_Focus_Duration**: The Elapsed_Focus_Duration calculated using a Focus_Session start timestamp and Confirmation_Time_Timestamp.
- **Pomodoro_Demo_Interval**: A 10-second elapsed-time interval that begins at a Focus_Session start timestamp and is displayed for the hackathon demonstration.
- **Subject**: The optional learner-entered study category stored with a Focus_Record.
- **Memo**: The optional learner-entered note stored with a Focus_Record.
- **Normalized_Completion_Value**: A Subject or Memo value with leading and trailing whitespace removed, with a value containing no non-whitespace characters stored as absent.
- **Daily_Record_Set**: Focus_Records whose end timestamps fall within the device calendar day containing the current timestamp.
- **Focus_Coaching_Message**: One sentence displayed to the learner and derived from the Daily_Record_Set.
- **UserDefaults_Store**: The on-device UserDefaults storage available to StudyFocus_App.
- **Uncategorized**: The statistics label used for Focus_Records with an absent Subject.

## Requirements

### Requirement 1: Start a titled focus session

**User Story:** As a learner, I want to enter a session title and start a focus session, so that I can identify the work I intend to do.

#### Acceptance Criteria

1. WHEN the learner requests session start with a Session_Title whose Normalized_Session_Title is non-empty, THE StudyFocus_App SHALL create exactly one active Focus_Session with the Normalized_Session_Title and Processing_Time_Timestamp as the start timestamp.
2. WHILE the Session_Title input contains no non-whitespace characters, THE StudyFocus_App SHALL present the session-start control as unavailable.
3. WHILE a Focus_Session is active, THE StudyFocus_App SHALL display the active Focus_Session Session_Title.

### Requirement 2: Calculate and display elapsed time

**User Story:** As a learner, I want to see accurate elapsed focus time, so that I can track the duration of my current work.

#### Acceptance Criteria

1. WHILE a Focus_Session is active, THE StudyFocus_App SHALL calculate Elapsed_Focus_Duration by rounding down to whole seconds the difference between the Focus_Session start timestamp and the current timestamp, clamped to zero seconds.
2. WHEN the learner ends an active Focus_Session, THE StudyFocus_App SHALL calculate Elapsed_Focus_Duration by rounding down to whole seconds the difference between the Focus_Session start timestamp and the end timestamp, clamped to zero seconds.
3. WHILE a Focus_Session is active, THE StudyFocus_App SHALL update the displayed Elapsed_Focus_Duration at least once per second without changing the Focus_Session start timestamp.

### Requirement 3: Demonstrate the Pomodoro interval

**User Story:** As a hackathon demonstrator, I want a short Pomodoro interval, so that I can show the timer behavior during a presentation.

#### Acceptance Criteria

1. WHEN the learner starts a Focus_Session, THE StudyFocus_App SHALL start a Pomodoro_Demo_Interval of 10 seconds from the Focus_Session start timestamp.
2. WHILE the elapsed duration from the Focus_Session start timestamp is less than 10 seconds, THE StudyFocus_App SHALL display a remaining whole-second count from 10 through 1 for the Pomodoro_Demo_Interval.
3. WHEN the elapsed duration from the Focus_Session start timestamp is greater than or equal to 10 seconds, THE StudyFocus_App SHALL display that the Pomodoro_Demo_Interval is complete.

### Requirement 4: Capture completion details and save a record

**User Story:** As a learner, I want to add a subject and memo when I finish, so that I can understand my completed focus time later.

#### Acceptance Criteria

1. WHEN the learner requests the end of an active Focus_Session, THE StudyFocus_App SHALL present optional inputs for Subject and Memo.
2. WHEN the learner confirms completion details, THE StudyFocus_App SHALL create a Focus_Record containing the active Focus_Session Session_Title, start timestamp, Confirmation_Time_Timestamp as the end timestamp, Final_Elapsed_Focus_Duration, and Normalized_Completion_Value values for Subject and Memo.
3. WHEN StudyFocus_App creates a Focus_Record, THE StudyFocus_App SHALL save the Focus_Record in UserDefaults_Store.
4. IF UserDefaults_Store cannot save a Focus_Record, THEN THE StudyFocus_App SHALL preserve the completion inputs and present feedback that identifies the save failure.
5. WHEN StudyFocus_App launches, THE StudyFocus_App SHALL load saved Focus_Records from UserDefaults_Store.
6. IF UserDefaults_Store cannot load or decode saved Focus_Records, THEN THE StudyFocus_App SHALL display statistics using an empty Focus_Record collection.

### Requirement 5: Show completed-focus statistics

**User Story:** As a learner, I want to review my focus statistics, so that I can see where I invested study time.

#### Acceptance Criteria

1. WHEN StudyFocus_App displays statistics, THE StudyFocus_App SHALL display total focus time as the sum of Elapsed_Focus_Duration with each saved Focus_Record included once.
2. WHEN StudyFocus_App displays statistics, THE StudyFocus_App SHALL display a separate total Elapsed_Focus_Duration for each non-absent Subject represented by saved Focus_Records.
3. WHEN StudyFocus_App displays statistics for a Focus_Record with an absent Subject, THE StudyFocus_App SHALL include the Focus_Record Elapsed_Focus_Duration in the Uncategorized total.
4. WHEN StudyFocus_App displays statistics, THE StudyFocus_App SHALL display a daily chart with one value per device calendar day represented by saved Focus_Records, where each value equals the sum of Elapsed_Focus_Duration for Focus_Records whose end timestamps fall on that device calendar day.
5. WHEN no Focus_Records are saved, THE StudyFocus_App SHALL display an empty-statistics state that states that no completed focus sessions have been recorded.

### Requirement 6: Provide daily focus coaching

**User Story:** As a learner, I want a short coaching message based on today’s activity, so that I can receive immediate focus guidance.

#### Acceptance Criteria

1. WHEN StudyFocus_App displays statistics, THE StudyFocus_App SHALL derive exactly one Focus_Coaching_Message from the Daily_Record_Set.
2. WHEN the Daily_Record_Set contains no Focus_Records, THE StudyFocus_App SHALL display a Focus_Coaching_Message that invites the learner to start a Focus_Session.
3. WHEN the Daily_Record_Set contains one or more Focus_Records, THE StudyFocus_App SHALL display a Focus_Coaching_Message that states the total Elapsed_Focus_Duration in the Daily_Record_Set.
4. WHEN StudyFocus_App displays a Focus_Coaching_Message, THE StudyFocus_App SHALL display exactly one sentence.
