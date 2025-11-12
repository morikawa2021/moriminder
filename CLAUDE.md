# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Moriminder** is an iOS task management application designed to help users who repeatedly snooze reminders and eventually forget their tasks. The app makes notifications harder to ignore and helps ensure tasks are actually completed.

### Key Design Principles
- **Simplicity first**: Keep operations as simple as possible
- **Reduce cognitive load**: Minimize both input burden and thinking required
- **Robust execution support**: Rich features for task execution and preventing forgotten schedules

## Project Status

This is currently a **documentation-only repository** with no code implementation yet. The project has detailed requirements and design specifications in Japanese located in the `docs/` directory:
- `docs/要求仕様書.md` - Requirements specification
- `docs/詳細仕様書.md` - Detailed design specification

## Architecture (Planned Implementation)

### Architecture Pattern
- **MVVM (Model-View-ViewModel)** pattern for high compatibility with SwiftUI
- Target: **iOS 15.0+**
- Language: **Swift**
- UI Framework: **SwiftUI** (recommended) or UIKit

### Layer Structure
```
Presentation Layer (Views, ViewModels, ViewModifiers)
    ↓
Business Logic Layer (UseCases, Services, Managers)
    ↓
Data Layer (Repositories, DataSources)
    ↓
Persistence Layer (Core Data / SwiftData)
```

### Core Components
1. **TaskManager**: CRUD operations for tasks
2. **NotificationManager**: Notification scheduling and management
3. **ReminderService**: Reminder logic execution
4. **AlarmService**: Alarm management
5. **CategoryManager**: Category management
6. **TaskSubdivisionService**: Task subdivision feature (LLM API integration)
7. **NaturalLanguageParser**: Date/time extraction from natural language
8. **RepeatingTaskGenerator**: Recurring task generation

## Data Model

### Core Entities

#### Task
- Basic info: `id`, `title`, `createdAt`, `completedAt`
- Classification: `category`, `priority` (low/medium/high)
- Date settings: `taskType` (task/schedule), `deadline`, `startDateTime`
- Notifications: `alarmDateTime`, `alarmSound`, `alarmEnabled`
- Reminders: `reminderEnabled`, `reminderInterval`, `reminderStartTime`, `reminderEndTime`
- Repeating: `isRepeating`, `repeatPattern`, `repeatEndDate`, `parentTaskId`
- State: `isCompleted`, `isArchived`

#### Category
- `id`, `name`, `color`, `createdAt`, `usageCount`, `tasks`

#### NotificationRecord
- `id`, `taskId`, `notificationId`, `scheduledTime`, `notificationType`, `isDelivered`, `deliveredAt`

### Key Enums
- **TaskType**: `task` (deadline-based) | `schedule` (start time-based)
- **Priority**: `low` | `medium` | `high`
- **RepeatPattern**: `daily` | `weekly` | `monthly` | `yearly` | `custom` | `nthWeekdayOfMonth` | `everyNDays`
- **NotificationType**: `alarm` | `reminder`

## Key Features

### 1. Task/Schedule Management
- **Tasks**: Deadline-based items that can be completed before the deadline
- **Schedules**: Start time-based items (with warnings if completed before start time)
- Both can be set together, with deadline taking priority for reminders

### 2. Reminder System
Simple, user-controlled reminder settings with three parameters:

**Configuration:**
- **Start Time**: When to begin sending reminders (default: 1 hour before deadline/start time)
- **Interval**: How often to send reminders (5min, 15min, 30min, 1hr, 3hr, 6hr, 12hr, 24hr)
- **End Time**: When to stop sending reminders (optional, default: until task completion)

**Key Points:**
- Unified settings for both tasks and schedules (no automatic adjustment by priority/type)
- Users have full control over timing and frequency
- Reminders continue indefinitely if no end time is set
- Limited only by iOS 64-notification system limit

### 3. Natural Language Parsing
- Automatically extract date/time from task titles
- Example: "明日の午後3時に会議" → Auto-set start time
- Example: "来週の月曜日までに提出" → Auto-set deadline
- Voice input support via Siri Shortcuts

### 4. Task Subdivision (LLM Integration)
- Triggered after 1 week of incomplete tasks
- Calls LLM API to suggest breaking tasks into 3-5 subtasks
- User can approve, modify, or reject suggestions
- Requires network connection (OpenAI API or similar)

### 5. Recurring Tasks
- Patterns: daily, weekly, monthly, yearly, custom, nth weekday of month, every N days
- Each instance managed independently
- Inherits reminder settings from parent

## Notification System

### Notification Categories
- **ALARM**: One-time notification at specified time
- **REMINDER**: Repeated notifications at set intervals

### Notification Actions
- **Complete**: Requires confirmation dialog (completes the task and stops all notifications)
- **Open**: Opens app to task detail

**Note**: Stop functionality is intentionally NOT available from notifications to prevent users from easily silencing reminders. Reminders can only be stopped from within the app (task detail/edit screens) with a confirmation dialog.

### Priority Mapping
- High priority → `UNNotificationInterruptionLevel.critical`
- Medium priority → `UNNotificationInterruptionLevel.timeSensitive`
- Low priority → `UNNotificationInterruptionLevel.active`

## Screen Structure (Planned)

### S001: Task List (Main Screen)
- Filter/sort bar at top
- Task cards showing: title, category, priority, date info, alarm/reminder icons, repeat icon
- Swipe actions for complete/delete
- Fixed "Add Task" button at bottom

### S002/S003: Task Add/Edit Screen
- Task name input with natural language parsing
- Category picker with autocomplete
- Priority selector (low/medium/high)
- Date settings: deadline vs start time (both possible)
- Preset time picker (12 common times + custom)
- Alarm settings (collapsible)
- Reminder settings (collapsible):
  - Start time picker (default: 1 hour before deadline/start time)
  - Interval picker (5min ~ 24hr)
  - Optional end time picker (default: until completion)
- Repeat settings (collapsible)

### S005: Task Subdivision Screen
- Shows original task
- Loading indicator during LLM processing
- List of suggested subtasks with checkboxes
- Actions: Approve, Edit, Reject
- Error handling with retry button

## Development Guidelines

### When Implementing

1. **Follow MVVM strictly**: Separate concerns between View, ViewModel, and Model layers

2. **Use async/await**: All data operations and API calls should use Swift's modern concurrency

3. **Error handling**: Define custom error types (`TaskError`, `NotificationError`, `APIError`) with localized descriptions

4. **Natural language parsing**: Use `NSDataDetector` for date extraction from Japanese text

5. **Notification scheduling**:
   - Schedule all reminders in advance (not just next one)
   - Clean up notifications when tasks complete
   - Handle notification limits (iOS has a 64 notification limit per app)

6. **LLM API integration**:
   - Timeout: 10 seconds
   - Show loading indicator
   - Handle network errors gracefully
   - Only send task title (privacy consideration)

7. **Data persistence**:
   - Use Core Data or SwiftData
   - Add indexes on: id, createdAt, deadline, startDateTime
   - Implement batch operations for performance

8. **Accessibility**:
   - Support Dynamic Type
   - Provide VoiceOver labels
   - Maintain appropriate contrast ratios

### Testing Strategy

**Unit tests for:**
- TaskManager CRUD operations
- Reminder interval calculations (all priority/type combinations)
- Natural language parsing
- Recurring task generation

**Integration tests for:**
- Complete task registration flow
- Reminder notification flow
- Task subdivision flow

**UI tests for:**
- All main screens
- Swipe actions
- Form validations

### Performance Targets
- App launch: < 3 seconds
- Task creation: < 1 second
- Notification delivery: ± 1 minute of scheduled time
- LLM API call: < 10 seconds (with timeout)

## Privacy & Security

- All user data stored locally (Core Data/SwiftData)
- API keys stored securely in Keychain
- LLM API only receives task title (no other personal data)
- Explicit user notification on first LLM use
- Privacy policy must document data transmission

## File Organization (Recommended)

```
Moriminder/
├── App/
│   ├── MoriminderApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Task.swift
│   ├── Category.swift
│   ├── NotificationRecord.swift
│   └── Enums/
├── Views/
│   ├── TaskList/
│   ├── TaskEdit/
│   ├── TaskSubdivision/
│   └── Components/
├── ViewModels/
│   ├── TaskListViewModel.swift
│   ├── TaskEditViewModel.swift
│   └── TaskSubdivisionViewModel.swift
├── Services/
│   ├── TaskManager.swift
│   ├── NotificationManager.swift
│   ├── ReminderService.swift
│   ├── AlarmService.swift
│   ├── TaskSubdivisionService.swift
│   └── NaturalLanguageParser.swift
├── Repositories/
│   └── TaskRepository.swift
├── API/
│   └── LLMAPIClient.swift
├── Utilities/
│   └── Extensions/
└── Resources/
    └── CoreData/
```

## Important Notes

- This app is designed for **Japanese users** - UI text and natural language parsing must support Japanese
- The app philosophy is to make notifications **harder to ignore** through continuous reminders - maintain this UX principle
- Always consider the **cognitive load** on users - provide defaults, presets, and smart suggestions
- The staged reminder system for schedules is complex - test thoroughly with various time ranges
