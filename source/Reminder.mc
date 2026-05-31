import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

//! Reminder data model
class Reminder {

    const TYPE_INTERVAL = 0;
    const TYPE_TIME = 1;

    var id as String;
    var text as String;
    var type as Number;
    var interval as Number;
    var time as String?;
    var enabled as Boolean;
    var lastTriggered as Number?;

    function initialize() {
        id = "";
        text = "";
        type = TYPE_INTERVAL;
        interval = 3600;
        time = null;
        enabled = true;
        lastTriggered = null;
    }

    function shouldFire() as Boolean {
        if (!enabled) {
            return false;
        }

        var now = System.getClockTime();

        if (type == TYPE_INTERVAL) {
            if (lastTriggered == null) {
                return true;
            }
            var elapsed = System.getTimer() - lastTriggered;
            return (elapsed >= interval);
        } else if (type == TYPE_TIME) {
            if (time == null) {
                return false;
            }
            var colonIdx = time.find(":");
            if (colonIdx == null || colonIdx == -1) {
                return false;
            }
            var hourStr = time.substring(0, colonIdx);
            var minStr = time.substring(colonIdx + 1, time.length());
            var targetHour = hourStr.toNumber();
            var targetMin = minStr.toNumber();

            if (targetHour == null || targetMin == null) {
                return false;
            }

            if (now.hour == targetHour && now.min == targetMin) {
                if (lastTriggered == null) {
                    return true;
                }
                return (System.getTimer() - lastTriggered) > 60;
            }
            return false;
        }
        return false;
    }

    function markTriggered() as Void {
        lastTriggered = System.getTimer();
    }

    function getScheduleDescription() as String {
        if (type == TYPE_INTERVAL) {
            var mins = interval / 60;
            if (mins < 60) {
                return "Every " + mins + " min";
            } else {
                var hrs = mins / 60;
                return "Every " + hrs + " hr(s)";
            }
        } else {
            if (time != null) {
                return "At " + time;
            }
            return "";
        }
    }

    function getDisplayText(maxLen as Number) as String {
        if (text.length() <= maxLen) {
            return text;
        }
        return text.substring(0, maxLen - 3) + "...";
    }
}
