# AGENTS.md

Instructions for AI coding agents working on this project.

## Project Overview

Custom Reminders is a Garmin Connect IQ watch app written in **Monkey C**. It lets users create recurring reminders with custom text, interval/time-of-day scheduling, vibration alerts, and popup notifications.

- **Language:** Monkey C (Garmin proprietary)
- **SDK:** Connect IQ 9.1.0 (min API 3.1.0)
- **Target device for testing:** Forerunner 245 (`fr245`)
- **Build system:** `monkeyc` compiler, `monkeydo` simulator launcher

## Quick Commands

```bash
# Build for FR245
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key

# Build with warnings
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key -w

# Build for all devices (package .iq)
bash build.sh

# Run in simulator
monkeydo bin/CustomReminders.prg fr245

# One-liner: build + launch
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key && \
monkeydo bin/CustomReminders.prg fr245

# Run all automated tests
./test.sh
```

## SDK Path

The build script assumes:
```
~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b
```

Update if your SDK version differs.

## Architecture

### Source Files

| File | Class(es) | Role |
|---|---|---|
| `CustomRemindersApp.mc` | `CustomRemindersApp`, `AlertDelegate` | App entry, foreground timer (30s), background data handler, alert popup |
| `Reminder.mc` | `Reminder` | Data model: `shouldFire()`, `markTriggered()`, `getScheduleDescription()` |
| `ReminderStore.mc` | `ReminderStore` | CRUD + JSON import from phone companion, max 20 reminders, `saveToStorage()` |
| `ReminderListView.mc` | `ReminderMenuView`, `ReminderMenuDelegate`, `ReminderActionsView`, `ReminderActionsDelegate`, `ReminderEditDelegate2` | Main list (Menu2), actions sub-menu, edit delegate bridge |
| `ReminderEditView.mc` | `ReminderEditView`, `TextInputDelegate` | 4-step add/edit wizard with TextPicker |
| `ReminderAlertView.mc` | `ReminderAlertView` | Full-screen popup when reminder fires |
| `ReminderBackgroundService.mc` | `ReminderBackgroundService` | Background 5-min temporal event, storage-based reminder check |
| `VibrationPattern.mc` | `VibrationPattern` | Vibration helper (2s at 100% intensity) |

### Key Design Decisions

1. **Delegate class hierarchy:**
   - `ReminderMenuDelegate extends InputDelegate` — needed for `onKey()` support (Menu2InputDelegate doesn't support it). Menu2 callbacks (`onSelect(item)`, `onBack()`, `onWrap()`) are dispatched by method signature regardless of parent class.
   - `ReminderActionsDelegate extends Menu2InputDelegate` — sub-menu only needs `onSelect`/`onBack`, so Menu2InputDelegate is fine.
   - `AlertDelegate extends BehaviorDelegate` — handles dismiss keys for the alert popup.
   - `ReminderEditDelegate2 extends BehaviorDelegate` — handles wizard navigation keys.
   - `TextInputDelegate extends TextPickerDelegate` — handles TextPicker completion/cancel.

2. **Reminder actions:** Reminders are regular `MenuItem` (not `ToggleMenuItem`). Selecting a reminder opens a `Menu2` sub-menu with Activate/Deactivate, Edit, Remove.

3. **Foreground timer:** A `Timer.Timer` fires every 30 seconds, iterates reminders via `shouldFire()`, calls `markTriggered()` + `store.updateReminder()`, then shows the alert popup + vibration.

4. **Background service:** Checks reminders every 5 minutes via temporal events. Stores `last_fired_text`/`last_fired_schedule` in Storage before waking the app.

5. **Alert handling:** `onBackgroundData()`, `onLayout()`, and the foreground timer all call `handleReminderAlert()`. An `_alertShowing` flag prevents stacking alerts.

6. **Menu rebuild:** `save()` in `ReminderEditView` and `rebuildAndShow()` in `ReminderMenuDelegate` use `switchToView()` to replace the current view with a fresh menu.

7. **Vibration:** Uses `new Attention.VibeProfile(100, 2000)` (2s at 100%). The raw array format `[level, duration]` is not accepted by SDK 9.1.0.

### Manifest Device IDs

Only devices recognized by SDK 9.1.0 are listed in `manifest.xml`. If you add a device that's not recognized, the build will fail with "device not recognized". Remove unknown IDs or verify against the SDK.

## Input Model (FR245)

| Physical Button | Menu2 Context | Delegate Event |
|---|---|---|
| Start (top-right) | Select item | `onSelect(item)` → actions sub-menu or add flow |
| Start (top-right) | Raw key | `onKey(KEY_START)` → add flow |
| Up (middle-left) | Navigate up | Menu2 handles internally; `onWrap(KEY_UP)` at boundary |
| Down (bottom-left) | Navigate down | Menu2 handles internally; `onWrap(KEY_DOWN)` at boundary |
| Back (bottom-right) | Back | `onBack()` |

**Note:** `KEY_UP` and `KEY_DOWN` are completely intercepted by Menu2 — they never reach `onKey()`, `onKeyPressed()`, or `onKeyReleased()`. Long press of UP cannot be detected on this device. There is no dedicated Menu button on FR245.

## Monkey C Gotchas

- **`item.getId()` returns `Object`**, not `String`. Use `.equals()` for comparison, never `==`.
- **`Menu2InputDelegate` does not support `onKey()`** — it inherits from `Object`, not `InputDelegate`. Extend `InputDelegate` instead if you need raw key events.
- **`BehaviorDelegate` has a parameterless `onSelect()`** that conflicts with Menu2's `onSelect(item)`. Don't extend `BehaviorDelegate` if you need `onSelect(item)`.
- **`TextPicker` pops itself** after `onTextEntered`/`onCancel` returns. Don't call `popView` in these callbacks.
- **`Attention.vibrate()` API** has changed across SDK versions. SDK 9.x requires `Array<VibeProfile>`, not raw `[level, duration]` arrays. Use `new Attention.VibeProfile(level, duration)`.
- **String comparison** — use `.equals()`, not `==`, for Object-typed values like `item.getId()`.
- **`onWrap()` returns Boolean** — return `true` to allow wrap-around, `false` to prevent it.

## Testing

### Simulator Testing

The simulator uses keyboard keys mapped to watch buttons:
- Enter = Select
- Arrow keys = Up/Down
- Escape = Back
- m = Menu (on some devices)

### Automated Tests (`test.sh`)

Requires `cliclick` (`brew install cliclick`) and macOS Accessibility permission. Tests simulate button presses via AppleScript + cliclick and capture screenshots.

### Verifying Logs

The simulator shows `System.println` output in the terminal where `monkeydo` was launched. Add `System.println()` calls to trace execution.

## Adding New Features

1. **New reminder type:** Add a constant in `Reminder.mc`, update `shouldFire()` in both `Reminder.mc` and `ReminderBackgroundService.mc`.
2. **New wizard step:** Add a step constant in `ReminderEditView.mc`, update `onSelect`/`onUp`/`onDown`/`onBackPressed`/`onMenu` handlers.
3. **New interval:** Add to `INTERVALS` and `INTERVAL_LABELS` arrays in `ReminderEditView.mc`.
4. **New device:** Add `<iq:product id="..."/>` to `manifest.xml`. Verify the ID is recognized by your SDK version.
