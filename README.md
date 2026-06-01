# Custom Reminders

A Garmin Connect IQ watch application that lets you set custom, recurring reminders on your watch with randomized vibration patterns.

## Features

- **Interval-based reminders** — Set reminders to fire every 5 min, 15 min, 30 min, 1 hour, or 2 hours
- **Time-of-day reminders** — Set reminders for specific times (e.g., 14:00)
- **Custom text** — Each reminder displays your own custom message
- **Random vibration patterns** — 1-10 vibrations with randomized short/long durations and pauses
- **On-watch management** — Add, edit, toggle reminders directly from the watch
- **Phone companion** — Manage reminders from Garmin Connect Mobile (settings screen)
- **Background execution** — Reminders fire even when the app is not open
- **Persistent storage** — Reminders survive watch reboots

## Supported Devices

| Family | Models |
|---|---|
| Forerunner | 245, 245M, 55, 255, 255M, 255S, 255SM, 265, 265S, 945, 945 LTE, 955, 955S, 965, 165, 165M |
| Fenix 6 | All variants (6, 6S, 6X, 6 Pro, 6S Pro, 6X Pro) |
| Fenix 7 | 7, 7S, 7X, 7 Pro, 7S Pro, 7X Pro, 7 Pro No WiFi, 7X Pro No WiFi |
| Fenix 8 | 43mm, 47mm, Pro 47mm, Solar 47mm, Solar 51mm |
| Epix | 2, 2 Pro (42mm, 47mm, 51mm) |
| Venu | 2, 2S, 2 Plus, 3, 3S, Sq, Sq 2 |
| Instinct 2 | 2, 2S, 2X |
| Vivoactive | 4, 4S, 5 |
| Enduro | 1, 3 |
| MARQ | Gen 2 (all variants) |
| D2 | Mach 1, Mach 2 |
| Descent | Mk 2, Mk 2S, G1 |

## Requirements

- **Garmin Connect IQ SDK 3.3+** (for FR245 support)
- **Developer key** — Generated via Garmin Connect IQ SDK Manager
- **Java 8+** — Required by the Connect IQ compiler

## Project Structure

```
custom_reminders/
├── manifest.xml                          # App manifest (devices, permissions, settings)
├── monkey.jungle                         # Build configuration
├── build.sh                              # Build script
├── bin/
│   └── CustomReminders.iq               # Compiled app package
├── source/
│   ├── CustomRemindersApp.mc             # Main app entry point
│   ├── Reminder.mc                       # Reminder data model
│   ├── ReminderStore.mc                  # Persistent storage manager
│   ├── ReminderListView.mc               # Reminder list UI
│   ├── ReminderEditView.mc               # Add/edit reminder wizard
│   ├── ReminderAlertView.mc              # Reminder popup alert
│   ├── ReminderBackgroundService.mc      # Background timer service
│   └── VibrationPattern.mc               # Random vibration generator
└── resources/
    ├── strings/strings.xml               # Localized strings
    ├── drawables/                        # Launcher icon
    ├── layouts/                          # Default layouts
    ├── properties/properties.xml         # Settings properties
    └── settings/
        ├── settings.xml                  # Settings schema
        └── settings.html                 # Phone companion UI
```

## Building

### Quick Build (single device)

```bash
# Build for Forerunner 245
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key
```

### Build for All Devices

```bash
# Full build (all devices in manifest)
monkeyc -w --package-app -y ../developer_key -f monkey.jungle -o bin/CustomReminders.iq
```

### Build Options

| Flag | Description |
|---|---|
| `-d <device>` | Target a specific device (e.g., `fr245`, `fr255`, `venu3`) |
| `-o <output>` | Output file path |
| `-y <key>` | Path to your developer key file or directory |
| `-f <jungle>` | Jungle build file |
| `--package-app` | Create an installable `.iq` package for all devices |
| `-w` | Show warnings |

## Running in the Simulator

```bash
# Run the FR245 build in the simulator
monkeydo bin/CustomReminders.prg fr245
```

### Simulator Controls

| Button | Action |
|---|---|
| **Select / Center** | Toggle reminder on/off, add character in editor, save |
| **Menu / Top** | Add new reminder, finish text input, confirm save |
| **Up / Bottom** | Scroll up, change value up |
| **Down / Right** | Scroll down, change value down |
| **Back / Left** | Go back, delete character, cancel |

## Automated Testing

The project includes an automated test runner that builds, launches the simulator, and runs UI test scenarios.

### Prerequisites

```bash
# Install cliclick (macOS CLI mouse automation)
brew install cliclick
```

### Usage

```bash
# Run all automated tests
./test.sh

# Run a specific test
./test.sh test_add_reminder_flow

# List available tests
./test.sh list
```

### Available Tests

| Test | Description |
|---|---|
| `test_app_launches` | Verify app launches and shows the main reminder list screen |
| `test_add_reminder_flow` | Full flow: add a reminder via the 5-step wizard |
| `test_toggle_reminder` | Add a reminder and toggle it on/off |
| `test_reminder_alert` | Verify alert popup display (manual verification) |

### How It Works

1. **Build** — Compiles the app for FR245
2. **Launch** — Starts the Connect IQ simulator in the background
3. **Automate** — Uses AppleScript + `cliclick` to simulate button presses
4. **Capture** — Takes screenshots for visual verification in `test_screenshots/`
5. **Cleanup** — Closes the simulator after each test

### Manual Testing Loop

For interactive testing, use this loop in your terminal:

```bash
# One-liner: build → launch → test
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key && \
monkeydo bin/CustomReminders.prg fr245
```

In the simulator:
- Press **m** for Menu (add reminder)
- Press **Enter** for Select (confirm/add)
- Press **↑** / **↓** for navigation
- Press **Esc** for Back

## Adding Reminders (On-Watch)

The reminder creation wizard has 5 steps:

1. **Text** — Navigate character-by-character to type your reminder message
   - UP/DOWN: select character
   - SELECT: add character
   - BACK: delete last character
   - MENU: finish text input
2. **Type** — Choose "Interval" or "Time of Day"
3. **Schedule** — Select interval (5m/15m/30m/1h/2h) or set time
4. **Enable** — Toggle reminder active/inactive
5. **Confirm** — Review and save

## Phone Companion

When installed via Garmin Connect IQ Store or sideloaded through Garmin Connect Mobile, the app exposes a settings screen accessible from the Garmin Connect app:

- **Add/Edit/Delete** reminders from your phone
- **Toggle** reminders on/off with a switch
- Changes sync to the watch automatically

## Permissions

| Permission | Purpose |
|---|---|
| `Background` | Schedule and fire reminders when the app is not open |
| `Communications` | Sync reminder settings with Garmin Connect Mobile |

## Storage

- Reminders are stored in app storage (persistent across reboots)
- Maximum **20 reminders** per device
- Each reminder stores: id, text, type, interval/time, enabled state, last triggered timestamp

## Background Service

The background service runs on a **5-minute interval** (minimum reliable interval on Connect IQ):

1. Wakes up every 5 minutes
2. Checks all enabled reminders for due triggers
3. Fires the first matching reminder
4. Plays a randomized vibration pattern
5. Requests the app to wake and display the alert
6. Re-registers the next 5-minute timer

> **Note:** On devices with power save mode enabled, background services may be limited. A warning is displayed on the alert screen when power save is active.

## Vibration Patterns

Each reminder triggers a **randomized haptic pattern**:

- **1–10 individual vibrations** per reminder
- Each vibration is randomly **short (100ms)** or **long (500ms)**
- Each pause between vibrations is randomly **100ms** or **200ms**
- Uses `Attention.vibrate()` API (or `VibrationPlayer` on older SDKs)

## Known Limitations

- **FR245** requires SDK 3.3 (not SDK 9.x) for compilation
- **Long text** is truncated to ~20 characters in the list view
- **No snooze** — dismissing a reminder clears it until the next interval
- **Delete via context menu** — press Menu on a reminder to see Edit/Remove options
- **Minimum interval** of 5 minutes due to background timer constraints

## Troubleshooting

### Build fails with "device not recognized"
Ensure your SDK version supports the target device. FR245 requires SDK 3.3+.

### Build fails with "launcher icon size incompatible"
The launcher icon is 42×42 but some devices expect different sizes. The icon is auto-scaled; the warning is harmless.

### Reminders don't fire in background
- Ensure the `Background` permission is granted
- Disable power save mode on the watch
- Open the app at least once after installation to register the background timer

### Settings don't sync from phone
- Open the app after changing settings to trigger `onSettingsChanged()`
- Check that Garmin Connect Mobile is connected to the watch

## License

This project is provided as-is for educational purposes.

### Important: macOS Accessibility Permission

The automated tests require **Accessibility permission** for your terminal app to send keyboard events to the simulator:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Find your terminal app (Terminal.app, iTerm2, Warp, etc.)
3. Toggle it **ON**
4. Restart your terminal

Without this permission, you'll see:
```
osascript is not allowed to send keystrokes. (1002)
```

### Manual Quick-Test Loop

If you don't want to grant permissions, use this loop to manually test:

```bash
# Build and launch
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key && \
monkeydo bin/CustomReminders.prg fr245
```

Then interact with the simulator window directly.
