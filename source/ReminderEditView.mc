import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Wizard view for adding/editing reminders
class ReminderEditView extends WatchUi.View {

    const STEP_TEXT = 0;
    const STEP_TYPE = 1;
    const STEP_INTERVAL = 2;
    const STEP_TIME = 3;
    const STEP_ENABLED = 4;
    const STEP_CONFIRM = 5;

    const CHARS = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?-_";
    const INTERVALS = [300, 900, 1800, 3600, 7200];
    const INTERVAL_LABELS = ["5 min", "15 min", "30 min", "1 hour", "2 hours"];

    // Local copies of Reminder types since we can't access them as module constants
    const TYPE_INTERVAL = 0;
    const TYPE_TIME = 1;

    private var _store as ReminderStore;
    private var _editIndex as Number;
    private var _currentStep as Number;
    private var _reminderText as String = "";
    private var _reminderType as Number = 0;
    private var _reminderInterval as Number = 3600;
    private var _reminderEnabled as Boolean = true;
    private var _charIndex as Number = 0;
    private var _hour as Number = 14;
    private var _minute as Number = 0;
    private var _intervalIndex as Number = 3;

    function initialize(store as ReminderStore, editIndex as Number) {
        View.initialize();
        _store = store;
        _editIndex = editIndex;
        _currentStep = STEP_TEXT;

        // If editing an existing reminder, load its values
        if (editIndex >= 0) {
            var reminders = _store.getReminders();
            if (editIndex < reminders.size()) {
                var r = reminders[editIndex];
                _reminderText = r.text;
                _reminderType = r.type;
                _reminderInterval = r.interval;
                _reminderEnabled = r.enabled;

                // Find matching interval index
                for (var i = 0; i < INTERVALS.size(); i++) {
                    if (INTERVALS[i] == _reminderInterval) {
                        _intervalIndex = i;
                        break;
                    }
                }
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, height);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 15, Graphics.FONT_TINY, getStepTitle(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var contentY = height / 3;

        if (_currentStep == STEP_TEXT) {
            drawTextInput(dc, width, contentY);
        } else if (_currentStep == STEP_TYPE) {
            drawTypeSelect(dc, width, contentY);
        } else if (_currentStep == STEP_INTERVAL) {
            drawIntervalSelect(dc, width, contentY);
        } else if (_currentStep == STEP_TIME) {
            drawTimeSelect(dc, width, contentY);
        } else if (_currentStep == STEP_ENABLED) {
            drawEnabledToggle(dc, width, contentY);
        } else if (_currentStep == STEP_CONFIRM) {
            drawConfirm(dc, width, contentY);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height - 25, Graphics.FONT_TINY, "UP/DOWN:Change SELECT:Next", Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawTextInput(dc as Graphics.Dc, width as Number, y as Number) as Void {
        var displayText = _reminderText == "" ? "(empty)" : _reminderText;
        dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, displayText, Graphics.TEXT_JUSTIFY_CENTER);
        if (_charIndex < CHARS.length()) {
            var ch = CHARS.substring(_charIndex, _charIndex + 1);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, y + 40, Graphics.FONT_LARGE, ch, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function drawTypeSelect(dc as Graphics.Dc, width as Number, y as Number) as Void {
        var intervalLabel = (_reminderType == TYPE_INTERVAL ? "► " : "  ") + "Interval";
        var timeLabel = (_reminderType == TYPE_TIME ? "► " : "  ") + "Time of Day";
        dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, intervalLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, y + 40, Graphics.FONT_MEDIUM, timeLabel, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawIntervalSelect(dc as Graphics.Dc, width as Number, y as Number) as Void {
        for (var i = 0; i < INTERVAL_LABELS.size(); i++) {
            if (i == _intervalIndex) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, y + (i * 30), Graphics.FONT_MEDIUM, "► " + INTERVAL_LABELS[i], Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, y + (i * 30), Graphics.FONT_MEDIUM, "  " + INTERVAL_LABELS[i], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    hidden function drawTimeSelect(dc as Graphics.Dc, width as Number, y as Number) as Void {
        dc.drawText(width / 2, y, Graphics.FONT_LARGE, formatTime(_hour, _minute), Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawEnabledToggle(dc as Graphics.Dc, width as Number, y as Number) as Void {
        var status = _reminderEnabled ? "Enabled" : "Disabled";
        dc.drawText(width / 2, y, Graphics.FONT_LARGE, status, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawConfirm(dc as Graphics.Dc, width as Number, y as Number) as Void {
        dc.drawText(width / 2, y, Graphics.FONT_MEDIUM, "Save Reminder?", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, y + 35, Graphics.FONT_SMALL, _reminderText, Graphics.TEXT_JUSTIFY_CENTER);
        var schedule = (_reminderType == TYPE_INTERVAL) ? "Every " + INTERVAL_LABELS[_intervalIndex] : "At " + formatTime(_hour, _minute);
        dc.drawText(width / 2, y + 60, Graphics.FONT_SMALL, schedule, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function formatTime(hour as Number, minute as Number) as String {
        var h = hour < 10 ? "0" + hour : "" + hour;
        var m = minute < 10 ? "0" + minute : "" + minute;
        return h + ":" + m;
    }

    hidden function getStepTitle() as String {
        if (_currentStep == STEP_TEXT) { return "Step 1/5: Text"; }
        if (_currentStep == STEP_TYPE) { return "Step 2/5: Type"; }
        if (_currentStep == STEP_INTERVAL) { return "Step 3/5: Interval"; }
        if (_currentStep == STEP_TIME) { return "Step 3/5: Time"; }
        if (_currentStep == STEP_ENABLED) { return "Step 4/5: Enable"; }
        if (_currentStep == STEP_CONFIRM) { return "Step 5/5: Confirm"; }
        return "";
    }

    function onMenu() as Void {
        if (_currentStep == STEP_TEXT || _currentStep == STEP_CONFIRM) {
            nextStep();
        }
    }

    function onSelect() as Void {
        if (_currentStep == STEP_TEXT) {
            if (_charIndex < CHARS.length()) {
                _reminderText = _reminderText + CHARS.substring(_charIndex, _charIndex + 1);
            }
        } else if (_currentStep == STEP_TYPE) {
            nextStep();
        } else if (_currentStep == STEP_INTERVAL) {
            nextStep();
        } else if (_currentStep == STEP_TIME) {
            nextStep();
        } else if (_currentStep == STEP_ENABLED) {
            _reminderEnabled = !_reminderEnabled;
        } else if (_currentStep == STEP_CONFIRM) {
            saveReminder();
        }
    }

    function onUp() as Void {
        if (_currentStep == STEP_TEXT) {
            if (_charIndex > 0) { _charIndex--; }
        } else if (_currentStep == STEP_TYPE) {
            _reminderType = TYPE_INTERVAL;
        } else if (_currentStep == STEP_INTERVAL) {
            if (_intervalIndex > 0) {
                _intervalIndex--;
                _reminderInterval = INTERVALS[_intervalIndex];
            }
        } else if (_currentStep == STEP_TIME) {
            if (_charIndex == 0) { _hour = (_hour + 1) % 24; }
            else { _minute = (_minute + 5) % 60; }
        }
        WatchUi.requestUpdate();
    }

    function onDown() as Void {
        if (_currentStep == STEP_TEXT) {
            if (_charIndex < CHARS.length() - 1) { _charIndex++; }
        } else if (_currentStep == STEP_TYPE) {
            _reminderType = TYPE_TIME;
        } else if (_currentStep == STEP_INTERVAL) {
            if (_intervalIndex < INTERVALS.size() - 1) {
                _intervalIndex++;
                _reminderInterval = INTERVALS[_intervalIndex];
            }
        } else if (_currentStep == STEP_TIME) {
            if (_charIndex == 0) { _hour = (_hour + 23) % 24; }
            else { _minute = (_minute + 55) % 60; }
        }
        WatchUi.requestUpdate();
    }

    function onBackPressed() as Boolean {
        if (_currentStep == STEP_TEXT) {
            if (_reminderText.length() > 0) {
                _reminderText = _reminderText.substring(0, _reminderText.length() - 1);
            } else {
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            }
        } else if (_currentStep == STEP_TYPE) {
            _currentStep = STEP_TEXT;
        } else if (_currentStep == STEP_INTERVAL || _currentStep == STEP_TIME) {
            _currentStep = STEP_TYPE;
        } else if (_currentStep == STEP_ENABLED) {
            _currentStep = (_reminderType == TYPE_INTERVAL) ? STEP_INTERVAL : STEP_TIME;
        } else if (_currentStep == STEP_CONFIRM) {
            _currentStep = STEP_ENABLED;
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return false;
        }
        WatchUi.requestUpdate();
        return true;
    }

    hidden function nextStep() as Void {
        _currentStep++;
        if (_currentStep == STEP_TIME && _reminderType == TYPE_INTERVAL) {
            _currentStep = STEP_ENABLED;
        }
        if (_currentStep == STEP_INTERVAL && _reminderType == TYPE_TIME) {
            _currentStep = STEP_TIME;
        }
        WatchUi.requestUpdate();
    }

    hidden function saveReminder() as Void {
        if (_reminderText == "") { return; }

        // Edge case: max reminders check
        if (!_store.canAddMore() && _editIndex < 0) {
            System.println("Max reminders reached");
            return;
        }

        var reminder = new Reminder();
        reminder.text = _reminderText;
        reminder.type = _reminderType;
        reminder.interval = _reminderInterval;
        reminder.time = formatTime(_hour, _minute);
        reminder.enabled = _reminderEnabled;

        if (_editIndex >= 0) {
            var reminders = _store.getReminders();
            if (_editIndex < reminders.size()) {
                reminder.id = reminders[_editIndex].id;
                reminder.lastTriggered = reminders[_editIndex].lastTriggered;
                _store.updateReminder(reminder);
            }
        } else {
            reminder.id = "r_" + System.getTimer();
            _store.addReminder(reminder);
        }

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
