import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Time;

//! Background service for checking reminders
(:background)
class ReminderBackgroundService extends System.ServiceDelegate {

    private var _store as ReminderStore?;
    private var _lastCheckHour as Number? = null;
    private var _lastCheckMin as Number? = null;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        System.println("ReminderBackgroundService: onStart");
        try {
            _store = new ReminderStore();
            _store.loadFromStorage();
        } catch (ex) {
            System.println("ReminderBackgroundService: Storage load failed");
            _store = new ReminderStore();
        }
        checkReminders();
        registerNextEvent();
    }

    function onTemporalEvent() as Void {
        System.println("ReminderBackgroundService: temporal event");
        try {
            _store = new ReminderStore();
            _store.loadFromStorage();
        } catch (ex) {
            System.println("ReminderBackgroundService: Storage load failed");
            return;
        }
        checkReminders();
        registerNextEvent();
    }

    function onSettingsChanged() as Void {
        System.println("ReminderBackgroundService: settings changed");
        try {
            var jsonStr = Storage.getValue("reminders_json") as String?;
            if (jsonStr != null && jsonStr != "") {
                _store = new ReminderStore();
                _store.loadFromJson(jsonStr);
            }
        } catch (ex) {
            System.println("Settings error");
        }
    }

    function onStop() as Void {
        System.println("ReminderBackgroundService: onStop");
    }

    //! Register the next temporal event (5 minutes from now)
    hidden function registerNextEvent() as Void {
        try {
            var now = System.getClockTime();
            // Calculate epoch seconds for 5 minutes from now
            var nowEpoch = Time.now().value();
            var targetEpoch = nowEpoch + 300; // 5 minutes in seconds
            var targetMoment = new Time.Moment(targetEpoch);

            Background.registerForTemporalEvent(targetMoment);
            System.println("Timer registered for " + (now.min + 5) + " min from now");
        } catch (ex) {
            System.println("Timer registration error");
        }
    }

    hidden function checkReminders() as Void {
        var store = _store;
        if (store == null) { return; }

        var now = System.getClockTime();

        // Avoid firing more than once per minute for time-based reminders
        if (_lastCheckHour != null && _lastCheckMin != null &&
            _lastCheckHour == now.hour && _lastCheckMin == now.min) {
            return;
        }
        _lastCheckHour = now.hour;
        _lastCheckMin = now.min;

        var reminders = store.getReminders();
        for (var i = 0; i < reminders.size(); i++) {
            var reminder = reminders[i];
            if (reminder.shouldFire()) {
                System.println("Firing: " + reminder.text);

                reminder.markTriggered();
                store.updateReminder(reminder);

                // Play vibration
                VibrationPattern.playSimple();

                // Wake the app
                try {
                    Background.requestApplicationWake(reminder.text);
                } catch (ex) {
                    System.println("Wake error");
                }

                Background.exit(true);
                return;
            }
        }
    }
}
