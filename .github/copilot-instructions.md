# AI Agent Instructions for Daily Tasks App

## Architecture Overview

This is a **Flutter multi-platform task management app** (Web, Windows, Linux, macOS, iOS, Android) with mood-based task categorization.

### Core Components

- **`main.dart`**: Platform detection & SQLite initialization
  - Desktop (Windows/Linux/macOS) + Web use `sqflite_ffi` for SQLite
  - Web uses `sqflite_ffi_web`
- **`screens/home_screen.dart`**: Main stateful widget managing task lifecycle
- **`services/database_service.dart`**: Singleton database layer (SQLite with schema versioning)
- **`models/task.dart`**: Task entity with serialization (toMap/fromMap/toJson/fromJson)
- **`widgets/task_tile.dart`**: Reusable task card with mood-based gradient styling
- **`utils/mood_theme.dart`**: Centralized mood→gradient/icon/text-color mapping

### Data Flow

1. **HomeScreen** loads tasks via `DatabaseService.getTasks()`
2. User adds/updates/deletes task → `DatabaseService` CRUD methods
3. State notifies UI via `setState()` + `_sortTasks()`
4. **TaskTile** renders each task with mood gradient from `MoodTheme`

## Key Patterns & Conventions

### Database Design
- SQLite with version-aware migrations in `_initDB()`
- Schema v1: id, title, isCompleted, timestamp, mood
- Schema v2 added: `mood` column with `ALTER TABLE` migration
- **Always use `task.toMap()` for inserts/updates** (single source of truth)

### Mood System
Four mood presets (+ `'default'`): `'creative'`, `'focus'`, `'chill'`, `'energy'`
- Each mood has: unique gradient (`MoodTheme.gradients`), icon (`getIcon()`), text color
- New moods added to `MoodTheme` → automatically supported in UI
- Task mood defaults to `'default'` during deserialization

### Task Sorting
Disabled tasks sort below active ones; within group, sort by descending timestamp (newest first)
```dart
void _sortTasks() {
  _tasks.sort((a, b) {
    if (a.isCompleted == b.isCompleted) {
      return b.timestamp.compareTo(a.timestamp);
    }
    return a.isCompleted ? 1 : -1;
  });
}
```

### UI Conventions
- Material 3 with deep violet seedColor (`0xFF6200EA`), teal accent
- Task cards use gradient + subtle shadow (0.03 alpha, 10px blur)
- Dismissible tasks swipe right-to-delete with red background
- Completed tasks: strikethrough + 40% opacity
- Use `GoogleFonts.outfitTextTheme()` for consistent typography

## Developer Workflow

### Build & Run
```bash
flutter pub get          # Fetch dependencies
flutter run -d <device>  # Run on device (web/windows/linux/macos)
```

### Database Debugging
- SQLite stored in platform-specific paths (handled by `sqflite`)
- Access via `DatabaseService()` singleton; changes persist across app restarts
- Schema versioning in `_initDB()` handles migrations automatically

### Common Tasks

**Add Feature**:
1. Update `Task` model if adding fields (toMap/fromMap/toJson)
2. Create migration in `DatabaseService._initDB()` if schema changes
3. Update `HomeScreen` to use new field (state, UI, sorting if needed)
4. Add mood preset to `MoodTheme.gradients` if mood-related

**Fix Bug**:
- Check `_mounted` guard in async callbacks (e.g., `if (mounted) { setState(...) }`)
- Verify task sorting after state changes (called in `_toggleTaskType`, after deletions)

## Critical Dependencies

- `sqflite` + `sqflite_common_ffi` + `sqflite_ffi_web`: SQLite across platforms
- `uuid`: Generate task IDs
- `intl`: Date formatting (h:mm a)
- `google_fonts`: Custom typography (Outfit font family)
- `flutter_lints`: Linting rules (standard Flutter lint set)

## Testing & Validation

- Run `flutter analyze` for linting
- Manual testing on target platforms (Web, Windows, etc.)
- Schema migrations tested by verifying tasks persist after app update
