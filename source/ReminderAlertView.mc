import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Alert view when reminder fires with adaptive layout
class ReminderAlertView extends WatchUi.View {

    private var _reminderText as String;
    private var _scheduleInfo as String?;

    function initialize(text as String, scheduleInfo as String?) {
        View.initialize();
        _reminderText = text;
        _scheduleInfo = scheduleInfo;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        var gap = (h * 0.06).toNumber();
        var hasSchedule = (_scheduleInfo != null);

        // Calculate total block height to center vertically
        var titleH = Graphics.getFontHeight(Graphics.FONT_MEDIUM);
        var textH = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var totalH = titleH + gap + textH;
        if (hasSchedule) {
            totalH = totalH + gap + textH;
        }
        var startY = (h - totalH) / 2;

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, startY, Graphics.FONT_MEDIUM, "Reminder", Graphics.TEXT_JUSTIFY_CENTER);

        // Reminder text
        startY = startY + titleH + gap;
        dc.drawText(w / 2, startY, Graphics.FONT_SMALL, _reminderText, Graphics.TEXT_JUSTIFY_CENTER);

        // Schedule info
        if (hasSchedule) {
            startY = startY + textH + gap;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, startY, Graphics.FONT_SMALL, _scheduleInfo, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Power save warning at bottom
        var settings = System.getDeviceSettings();
        if (settings has :powerSave && settings.powerSave) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 15, Graphics.FONT_TINY, "Power save ON", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Input handled by AlertDelegate
}
