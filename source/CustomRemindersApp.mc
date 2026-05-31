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
}

//! Delegate for the list view - handles button input
class ReminderListDelegate extends WatchUi.BehaviorDelegate {

    private var _listView as ReminderListView;

    function initialize(listView as ReminderListView) {
        BehaviorDelegate.initialize();
        _listView = listView;
    }

    function onMenu() as Boolean {
        _listView.onMenu();
        return true;
    }

    function onSelect() as Boolean {
        _listView.onSelect();
        return true;
    }

    function onUp() as Boolean {
        _listView.onUp();
        return true;
    }

    function onDown() as Boolean {
        _listView.onDown();
        return true;
    }

    function onBackPressed() as Boolean {
        return false;
    }
}

class AlertDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onBackPressed() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return false;
    }
}
