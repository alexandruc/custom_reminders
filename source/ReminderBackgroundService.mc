import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Time;

//! Background service for checking reminders.
//! On SDK 3.x, this runs in an isolated process — all logic is inlined
//! here since we cannot import non-background classes.
(:background)
class ReminderBackgroundService extends System.ServiceDelegate {

    const STORAGE_PREFIX = "reminders_";
    const TYPE_INTERVAL = 0;
    const TYPE_TIME = 1;

    private var _lastCheckHour as Number? = null;
    private var _lastCheckMin as Number? = null;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        System.println("ReminderBackgroundService: onStart");
        checkReminders();
        registerNextEvent();
    }

    function onTemporalEvent() as Void {
        System.println("ReminderBackgroundService: temporal event");
        checkReminders();
        registerNextEvent();
    }

    function onSettingsChanged() as Void {
        System.println("ReminderBackgroundService: settings changed");
    }

    function onStop() as Void {
        System.println("ReminderBackgroundService: onStop");
    }

    //! Register the next temporal event (5 minutes from now)
    hidden function registerNextEvent() as Void {
        try {
            var nowEpoch = Time.now().value();
            var targetEpoch = nowEpoch + 300; // 5 minutes in seconds
            var targetMoment = new Time.Moment(targetEpoch);
            Background.registerForTemporalEvent(targetMoment);
            System.println("Timer set for 5 min from now");
        } catch (ex) {
            System.println("Timer error: " + ex);
        }
    }

    //! Load and check all reminders
    hidden function checkReminders() as Void {
        var now = System.getClockTime();

        // Debounce: don't check more than once per minute
        if (_lastCheckHour != null && _lastCheckMin != null &&
            _lastCheckHour == now.hour && _lastCheckMin == now.min) {
            return;
        }
        _lastCheckHour = now.hour;
        _lastCheckMin = now.min;

        var cnt = Storage.getValue(STORAGE_PREFIX + "count");
        if (cnt == null) { return; }
        var count = cnt as Number;

        for (var i = 0; i < count; i++) {
            var prefix = STORAGE_PREFIX + i;
            var enabled = Storage.getValue(prefix + "_enabled");
            if (enabled == null || enabled == false) { continue; }

            var rtype = Storage.getValue(prefix + "_type");
            if (rtype == null) { continue; }
            var rType = rtype as Number;
            var fired = false;

            if (rType == TYPE_INTERVAL) {
                var interval = Storage.getValue(prefix + "_interval");
                var lastTriggered = Storage.getValue(prefix + "_lastTriggered");
                if (interval == null) { continue; }

                var nowEpoch = Time.now().value();
                if (lastTriggered == null) {
                    fired = true;
                } else {
                    var elapsed = nowEpoch - (lastTriggered as Number);
                    if (elapsed >= (interval as Number)) {
                        fired = true;
                    }
                }
            } else if (rType == TYPE_TIME) {
                var timeStr = Storage.getValue(prefix + "_time");
                if (timeStr != null && timeStr != "") {
                    var timeVal = timeStr as String;
                    var colonIdx = timeVal.find(":");
                    if (colonIdx != null) {
                        var targetHour = timeVal.substring(0, colonIdx).toNumber();
                        var targetMin = timeVal.substring(colonIdx + 1, timeVal.length()).toNumber();
                        if (targetHour != null && targetMin != null) {
                            if (now.hour == targetHour && now.min == targetMin) {
                                var lastTriggered = Storage.getValue(prefix + "_lastTriggered");
                                if (lastTriggered == null) {
                                    fired = true;
                                } else {
                                    var nowEpoch = Time.now().value();
                                    if (nowEpoch - (lastTriggered as Number) > 60) {
                                        fired = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (fired) {
                var text = Storage.getValue(prefix + "_text");
                var displayText = "";
                if (text != null) {
                    displayText = text as String;
                }

                var scheduleInfo = "";
                if (rType == TYPE_INTERVAL) {
                    var mins = (Storage.getValue(prefix + "_interval") as Number) / 60;
                    scheduleInfo = "Every " + mins + " min";
                } else if (rType == TYPE_TIME) {
                    var t = Storage.getValue(prefix + "_time");
                    if (t != null) {
                        scheduleInfo = "At " + (t as String);
                    }
                }

                // Update last triggered
                Storage.setValue(prefix + "_lastTriggered", Time.now().value());

                // Store fired info for the foreground app to read
                Storage.setValue("last_fired_text", displayText);
                Storage.setValue("last_fired_schedule", scheduleInfo);

                // Wake the app to show alert and play vibration
                try {
                    Background.requestApplicationWake(displayText);
                } catch (ex) {
                    System.println("Wake error");
                }

                Background.exit(true);
                return;
            }
        }
    }
}
