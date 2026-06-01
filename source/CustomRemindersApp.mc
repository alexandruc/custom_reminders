import Toybox.Lang;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.System;

//! Main app class
class CustomRemindersApp extends Application.AppBase {

    private var _reminderStore as ReminderStore?;

    function initialize() {
        AppBase.initialize();
        _reminderStore = null;
    }

    function onStart(state as Dictionary?) as Void {
        System.println("CustomRemindersApp: onStart");
        _reminderStore = new ReminderStore();
        _reminderStore.loadFromStorage();
        checkPhoneSettings();
    }

    function onSettingsChanged() as Void {
        System.println("CustomRemindersApp: settings changed");
        checkPhoneSettings();
        // Rebuild the menu view to reflect changes
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
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var store = getStore();
        return [new ReminderMenuView(store), new ReminderMenuDelegate(store)];
    }

    //! Return the shared reminder store, creating it if needed
    function getStore() as ReminderStore {
        if (_reminderStore == null) {
            _reminderStore = new ReminderStore();
            _reminderStore.loadFromStorage();
        }
        return _reminderStore;
    }

    //! Return service delegate for background processing
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
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return false;
        }
        return false;
    }
}
