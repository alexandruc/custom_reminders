import Toybox.Lang;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Time;

class ReminderBackgroundService extends System.ServiceDelegate {

    const STORAGE_PREFIX = "reminders_";
    const TYPE_INTERVAL = 0;
    const TYPE_TIME = 1;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        System.println("ReminderBackgroundService: onStart");
        checkAndFire();
        scheduleNext();
    }

    function onTemporalEvent() as Void {
        System.println("ReminderBackgroundService: temporal event");
        checkAndFire();
        scheduleNext();
    }

    function onSettingsChanged() as Void {
        System.println("ReminderBackgroundService: settings changed");
    }

    function onStop() as Void {
        System.println("ReminderBackgroundService: onStop");
    }

    hidden function scheduleNext() as Void {
        try {
            var targetEpoch = Time.now().value() + 300;
            Background.registerForTemporalEvent(new Time.Moment(targetEpoch));
            System.println("Bkgd: next event in 5 min");
        } catch (ex) {
            System.println("Bkgd: sched error " + ex);
        }
    }

    hidden function checkAndFire() as Void {
        try {
            var cnt = Storage.getValue(STORAGE_PREFIX + "count") as Number?;
            if (cnt == null || cnt <= 0) { return; }

            var nowEpoch = Time.now().value();
            var nowClock = System.getClockTime();

            for (var i = 0; i < cnt; i++) {
                var p = STORAGE_PREFIX + i;
                var enabled = Storage.getValue(p + "_enabled");
                if (enabled == null || enabled == false) { continue; }

                var rType = Storage.getValue(p + "_type") as Number?;
                if (rType == null) { continue; }

                var fired = false;

                if (rType == TYPE_INTERVAL) {
                    var interval = Storage.getValue(p + "_interval") as Number?;
                    if (interval == null) { continue; }

                    var lastTriggered = Storage.getValue(p + "_lastTriggered") as Number?;
                    if (lastTriggered == null) {
                        Storage.setValue(p + "_lastTriggered", nowEpoch);
                        continue;
                    }

                    if (nowEpoch - lastTriggered >= interval) {
                        fired = true;
                    }
                } else if (rType == TYPE_TIME) {
                    var timeStr = Storage.getValue(p + "_time") as String?;
                    if (timeStr == null || timeStr.length() == 0) { continue; }

                    var colonIdx = timeStr.find(":");
                    if (colonIdx == null) { continue; }

                    var targetHour = timeStr.substring(0, colonIdx).toNumber();
                    var targetMin = timeStr.substring(colonIdx + 1, timeStr.length()).toNumber();
                    if (targetHour == null || targetMin == null) { continue; }

                    if (nowClock.hour == targetHour && nowClock.min == targetMin) {
                        var lastTriggered = Storage.getValue(p + "_lastTriggered") as Number?;
                        if (lastTriggered == null || nowEpoch - lastTriggered > 60) {
                            fired = true;
                        }
                    }
                }

                if (fired) {
                    var text = Storage.getValue(p + "_text") as String?;
                    var displayText = text != null ? text : "";

                    var scheduleInfo = "";
                    if (rType == TYPE_INTERVAL) {
                        var mins = (Storage.getValue(p + "_interval") as Number?);
                        if (mins != null) { scheduleInfo = "Every " + (mins / 60) + " min"; }
                    } else {
                        var t = Storage.getValue(p + "_time") as String?;
                        if (t != null) { scheduleInfo = "At " + t; }
                    }

                    Storage.setValue(p + "_lastTriggered", nowEpoch);
                    Storage.setValue("last_fired_text", displayText);
                    Storage.setValue("last_fired_schedule", scheduleInfo);

                    try {
                        Background.requestApplicationWake(displayText);
                    } catch (ex) {
                        System.println("Bkgd: wake error");
                    }

                    Background.exit(true);
                    return;
                }
            }
        } catch (ex) {
            System.println("Bkgd: check error " + ex);
        }
    }
}
