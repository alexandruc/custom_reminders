import Toybox.Lang;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.System;

//! Main app class
class CustomRemindersApp extends Application.AppBase {

    private var _reminderStore as ReminderStore?;
    private var _listView as ReminderListView?;
    private var _listDelegate as ReminderListDelegate?;

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
        // Force list view to reload from storage
        WatchUi.requestUpdate();
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
        _listView = new ReminderListView();
        _listDelegate = new ReminderListDelegate(_listView);
        return [_listView, _listDelegate];
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

//! Delegate for the list view - handles button input via onKey
class ReminderListDelegate extends WatchUi.BehaviorDelegate {

    private var _listView as ReminderListView;

    function initialize(listView as ReminderListView) {
        BehaviorDelegate.initialize();
        _listView = listView;
    }

    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            System.println("*** Delegate onKey UP ***");
            _listView.onUp();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            System.println("*** Delegate onKey DOWN ***");
            _listView.onDown();
            return true;
        }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            System.println("*** Delegate onKey ENTER ***");
            _listView.onSelect();
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            System.println("*** Delegate onKey MENU ***");
            _listView.onMenu();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            return false;
        }
        return false;
    }
}

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
