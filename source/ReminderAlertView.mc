import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

//! Alert view when reminder fires
class ReminderAlertView extends WatchUi.View {

    private var _reminderText as String;
    private var _scheduleInfo as String?;

    function initialize(text as String, scheduleInfo as String?) {
        View.initialize();
        _reminderText = text;
        _scheduleInfo = scheduleInfo;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.ReminderAlertLayout(dc));
    }

    function onShow() as Void {
        var label = View.findDrawableById("ReminderText");
        if (label != null) {
            var txt = label as WatchUi.Text;
            if (txt != null) {
                txt.setText(_reminderText);
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, height);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(10, 30, width - 20, height - 60, 10);

        dc.drawText(width / 2, height / 5, Graphics.FONT_LARGE, "Reminder", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height / 3, Graphics.FONT_MEDIUM, _reminderText, Graphics.TEXT_JUSTIFY_CENTER);

        if (_scheduleInfo != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * 2 / 3, Graphics.FONT_SMALL, _scheduleInfo, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height - 40, Graphics.FONT_TINY, "SELECT to dismiss", Graphics.TEXT_JUSTIFY_CENTER);

        // Edge case warning: battery saver may affect reminders
        var settings = System.getDeviceSettings();
        if (settings has :powerSave && settings.powerSave) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 60, Graphics.FONT_TINY, "Power save ON", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function onMenu() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onSelect() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onBackPressed() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return false;
    }
}
