import Toybox.Lang;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Timer;

//! Main app class
class CustomRemindersApp extends Application.AppBase {

    private var _reminderStore as ReminderStore?;
    private var _alertShowing as Boolean = false;
    private var _alertTimer as Timer.Timer?;

    function initialize() {
        AppBase.initialize();
        _reminderStore = null;
    }

    function onStart(state as Dictionary?) as Void {
        System.println("CustomRemindersApp: onStart");
        _reminderStore = new ReminderStore();
        _reminderStore.loadFromStorage();
        _alertShowing = false;
        checkPhoneSettings();
        try {
            startForegroundChecks();
        } catch (ex) {
            System.println("Timer not available (background mode)");
        }
    }

    function onSettingsChanged() as Void {
        System.println("CustomRemindersApp: settings changed");
        checkPhoneSettings();
        var store = getStore();
        var menuView = new ReminderMenuView(store);
        var menuDelegate = new ReminderMenuDelegate(store);
        WatchUi.switchToView(menuView, menuDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    hidden function checkPhoneSettings() as Void {
        try {
            var jsonStr = Storage.getValue("reminders_json") as String?;
            if (jsonStr != null && jsonStr != "") {
                var store = _reminderStore;
                if (store != null) {
                    store.loadFromJson(jsonStr);
                    System.println("Settings applied");
                }
            }
        } catch (ex) {
            System.println("Settings error");
        }
    }

    function onStop(state as Dictionary?) as Void {
        System.println("CustomRemindersApp: onStop");
        try {
            stopForegroundChecks();
        } catch (ex) {
            System.println("Timer not available (background mode)");
        }
    }

    //! Called when the app is woken by Background.requestApplicationWake().
    function onBackgroundData(data) as Void {
        System.println("CustomRemindersApp: onBackgroundData");
        handleReminderAlert();
    }

    //! Called after the initial view is laid out — check for pending alert.
    function onLayout(dc as Graphics.Dc) as Void {
        handleReminderAlert();
    }

    //! Check if a reminder fired while in background and show alert + vibe.
    hidden function handleReminderAlert() as Void {
        if (_alertShowing) { return; }

        try {
            var text = Storage.getValue("last_fired_text");
            if (text == null || (text as String).length() == 0) {
                return;
            }
            _alertShowing = true;

            var reminderText = text as String;
            var scheduleInfo = Storage.getValue("last_fired_schedule");

            Storage.deleteValue("last_fired_text");
            Storage.deleteValue("last_fired_schedule");

            System.println("Showing alert for: " + reminderText);

            VibrationPattern.playLong();

            var alertView = new ReminderAlertView(
                reminderText,
                scheduleInfo as String?
            );
            var alertDelegate = new AlertDelegate();
            WatchUi.pushView(alertView, alertDelegate, WatchUi.SLIDE_IMMEDIATE);
        } catch (ex) {
            System.println("Alert error: " + ex);
        }
    }

    //! Called by AlertDelegate when the alert popup is dismissed.
    function resetAlertShowing() as Void {
        _alertShowing = false;
        System.println("Alert dismissed, resuming checks");
    }

    // ── Foreground timer ──

    hidden function startForegroundChecks() as Void {
        try {
            _alertTimer = new Timer.Timer();
            _alertTimer.start(method(:onForegroundCheck), 30000, true);
            System.println("Foreground timer started (30s)");
        } catch (ex) {
            System.println("Timer start error: " + ex);
        }
    }

    hidden function stopForegroundChecks() as Void {
        if (_alertTimer != null) {
            _alertTimer.stop();
            _alertTimer = null;
            System.println("Foreground timer stopped");
        }
    }

    //! Timer callback — checks all reminders and fires alerts.
    function onForegroundCheck() as Void {
        if (_alertShowing) { return; }

        var store = _reminderStore;
        if (store == null) { return; }

        var reminders = store.getReminders();
        for (var i = 0; i < reminders.size(); i++) {
            var r = reminders[i];
            if (r.shouldFire()) {
                System.println("Foreground check: reminder fired — " + r.text);

                var scheduleInfo = r.getScheduleDescription();
                r.markTriggered();
                store.updateReminder(r);

                Storage.setValue("last_fired_text", r.text);
                Storage.setValue("last_fired_schedule", scheduleInfo);

                handleReminderAlert();
                return;
            }
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var store = getStore();
        return [new ReminderMenuView(store), new ReminderMenuDelegate(store)];
    }

    function getStore() as ReminderStore {
        if (_reminderStore == null) {
            _reminderStore = new ReminderStore();
            _reminderStore.loadFromStorage();
        }
        return _reminderStore;
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new ReminderBackgroundService()];
    }
}

// ReminderMenuDelegate and ReminderMenuView are defined in ReminderListView.mc

class AlertDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            notifyDismissed();
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            notifyDismissed();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            notifyDismissed();
            return false;
        }
        return false;
    }

    hidden function notifyDismissed() as Void {
        var app = Application.getApp();
        if (app instanceof CustomRemindersApp) {
            (app as CustomRemindersApp).resetAlertShowing();
        }
    }
}
