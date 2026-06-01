# Custom Reminders

A Garmin Connect IQ watch application that lets you set custom, recurring reminders on your watch.

## Features

- **Interval-based reminders** — Set reminders to fire every 1 min, 5 min, 15 min, 30 min, 1 hour, or 2 hours
- **Time-of-day reminders** — Set reminders for a specific time (e.g., 14:00)
- **Custom text** — Each reminder displays your own message (entered via the built-in TextPicker)
- **Vibration alert** — 2-second vibration at full intensity when a reminder fires
- **Popup alert** — Full-screen notification with reminder name and schedule info
- **Foreground timer** — Checks reminders every 30 seconds while the app is open
- **Background service** — Checks reminders every 5 minutes when the app is closed
- **On-watch management** — Add, edit, activate/deactivate, and delete reminders from the watch
- **Phone companion** — Manage reminders from Garmin Connect Mobile (settings screen)
- **Persistent storage** — Up to 20 reminders survive watch reboots

## Supported Devices

| Family | Models |
|---|---|
| Forerunner | 245, 245M, 255, 255M, 255S, 255SM, 265, 265S, 945, 955, 965, 165, 165M |
| Fenix 7 | 7, 7S, 7X, 7 Pro, 7S Pro, 7X Pro, 7 Pro No WiFi, 7X Pro No WiFi |
| Epix | 2, 2 Pro (42mm, 47mm, 51mm) |
| Venu | 2 Plus, 3, 3S |
| Vivoactive | 5 |
| Enduro | 3 |
| MARQ | Gen 2 (all variants) |
| D2 | Mach 1 |

## Requirements

- **Connect IQ SDK 9.1.0** (installed via Garmin SDK Manager)
- **Developer key** — Generated via Garmin Connect IQ SDK Manager
- **Java 8+** — Required by the Connect IQ compiler

## Project Structure

```
custom_reminders/
├── manifest.xml                          # App manifest (devices, permissions, settings)
├── monkey.jungle                         # Build configuration
├── build.sh                              # Build script (all devices)
├── test.sh                               # Automated test runner
├── bin/                                  # Build output
├── source/
│   ├── CustomRemindersApp.mc             # App entry point, foreground timer, alert handling
│   ├── Reminder.mc                       # Reminder data model (shouldFire, markTriggered)
│   ├── ReminderStore.mc                  # Persistent storage CRUD (max 20)
│   ├── ReminderListView.mc               # Main list UI (Menu2), actions sub-menu, edit delegate
│   ├── ReminderEditView.mc               # Add/edit wizard (TextPicker → Type → Schedule → Confirm)
│   ├── ReminderAlertView.mc              # Full-screen alert popup
│   ├── ReminderBackgroundService.mc      # Background temporal event (5-min timer)
│   └── VibrationPattern.mc               # Vibration helper
├── resources/
│   ├── strings/strings.xml               # Localized strings
│   ├── drawables/                        # Launcher icon
│   ├── layouts/                          # Default layouts
│   ├── properties/properties.xml         # Settings properties
│   └── settings/
│       ├── settings.xml                  # Settings schema
│       └── settings.html                 # Phone companion HTML/JS UI
├── resources-round/                      # Round device layouts
├── resources-rectangle/                  # Rectangle device layouts
├── resources-416x416/                    # 416×416 display layouts
└── resources-454x454/                    # 454×454 display layouts
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
bash build.sh
```

### Build Options

| Flag | Description |
|---|---|
| `-d <device>` | Target a specific device (e.g., `fr245`, `fenix7`, `venu3`) |
| `-o <output>` | Output file path |
| `-y <key>` | Path to your developer key file |
| `-f <jungle>` | Jungle build file |
| `-w` | Show warnings |
| `-l <level>` | Type check level (0=off, 1=gradual, 2=informative, 3=strict) |

## Running in the Simulator

```bash
# Build and launch
monkeyc -f monkey.jungle -o bin/CustomReminders.prg -d fr245 -y ../developer_key && \
monkeydo bin/CustomReminders.prg fr245
```

### Simulator Controls (FR245)

| Key | Button | Action |
|---|---|---|
| **Enter** | Select | Select item, confirm |
| **↑** | Up | Navigate up |
| **↓** | Down | Navigate down |
| **Esc** | Back | Go back |
| **m** | Menu | (varies by device) |

## On-Watch Interaction

### Main List

| Action | How |
|---|---|
| **Add reminder** | Press **Start** on the main list |
| **Open actions** | Press **Select** on a reminder |
| **Navigate** | Up/Down buttons |
| **Go back** | Back button |

### Reminder Actions Sub-Menu

When you select a reminder, a sub-menu appears with:

| Option | Description |
|---|---|
| **Activate / Deactivate** | Toggle the reminder on or off |
| **Edit** | Open the edit wizard to change the reminder |
| **Remove** | Delete the reminder permanently |

### Add/Edit Wizard

1. **Text** — Press Select to open the built-in TextPicker. Enter your reminder message and press Done.
2. **Type** — Choose "Interval" or "Time of Day"
3. **Schedule** — Select interval (1m/5m/15m/30m/1h/2h) or set a time (HH:MM)
4. **Confirm** — Review and save. Empty text is not allowed.

## Phone Companion

When installed via Garmin Connect IQ Store or sideloaded through Garmin Connect Mobile, the app exposes a settings screen accessible from the Garmin Connect app:

- **Add/Edit/Delete** reminders from your phone
- **Toggle** reminders on/off with a switch
- Changes sync to the watch automatically

## Automated Testing

The project includes an automated test runner that builds, launches the simulator, and runs UI test scenarios.

### Prerequisites

```bash
brew install cliclick
```

Also grant **Accessibility permission** to your terminal app:
1. System Settings → Privacy & Security → Accessibility
2. Toggle your terminal app ON
3. Restart your terminal

### Usage

```bash
# Run all tests
./test.sh

# Run a specific test
./test.sh test_add_reminder_flow

# List available tests
./test.sh list
```

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

1. Wakes up every 5 minutes via `Background.registerForTemporalEvent()`
2. Checks all enabled reminders against the current time
3. If a reminder is due, stores the reminder text and schedule in storage
4. Calls `Background.requestApplicationWake()` to wake the app
5. On wake, the app plays a vibration and shows the alert popup

When the app is in the **foreground**, a `Timer.Timer` checks reminders every **30 seconds** for faster responsiveness.

## Known Limitations

- **No snooze** — dismissing a reminder clears it until the next interval
- **Minimum background interval** of 5 minutes due to temporal event constraints
- **Long text** is truncated to ~16 characters in the list view
- **Vibration pattern** uses a single 2-second pulse (random pattern API requires 3.2.0+ but FR245 runs 3.1.0)
- **Long press of Menu/Up button** cannot be detected on devices without a dedicated Menu key (like FR245). Use Select on a reminder to access the actions sub-menu instead.
- **Device compatibility** — the manifest lists only devices recognized by SDK 9.1.0. Older device IDs may need removal/addition.

## Troubleshooting

### Build fails with "device not recognized"
Ensure your SDK version supports the target device. If you need to add a device, check the device ID in the Garmin SDK documentation and add it to `manifest.xml`.

### Build fails with "launcher icon size incompatible"
The launcher icon is 42×42 but some devices expect different sizes. The icon is auto-scaled; the warning is harmless.

### Reminders don't fire in background
- Ensure the `Background` permission is granted
- Disable power save mode on the watch
- Open the app at least once after installation to register the background timer

### Reminders don't fire in foreground
- The foreground timer checks every 30 seconds — wait up to 30 seconds after the expected time
- Check that the reminder is enabled (Activate/Deactivate in the actions sub-menu)
- Check logs via `System.println` output in the simulator

### Settings don't sync from phone
- Open the app after changing settings to trigger `onSettingsChanged()`
- Check that Garmin Connect Mobile is connected to the watch
