import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Main list view using Menu2 with MenuItems for each reminder.
class ReminderMenuView extends WatchUi.Menu2 {

    private var _store as ReminderStore;

    function initialize(store as ReminderStore) {
        Menu2.initialize({:title => "Reminders"});
        _store = store;
        buildItems();
    }

    function buildItems() as Void {
        var reminders = _store.getReminders();
        for (var i = 0; i < reminders.size(); i++) {
            var r = reminders[i];
            var label = r.getDisplayText(16);
            if (!r.enabled) {
                label = label + " (off)";
            }
            var sub = r.getScheduleDescription();
            var item = new WatchUi.MenuItem(
                label,
                sub,
                i.toString(),
                {}
            );
            addItem(item);
        }
        addItem(new WatchUi.MenuItem(
            "+ Add new",
            null,
            "add_new",
            {}
        ));
    }

    function refresh() as Void {
    }
}

//! Delegate for ReminderMenuView.
//! Extends InputDelegate so onKey() works for KEY_START.
//! Menu2 dispatches onSelect(item) by method signature.
class ReminderMenuDelegate extends WatchUi.InputDelegate {

    private var _store as ReminderStore;

    function initialize(store as ReminderStore) {
        InputDelegate.initialize();
        _store = store;
    }

    //! Handle selection of a menu item.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var idStr = item.getId() as String;
        System.println("MenuDelegate.onSelect: " + idStr);

        if (idStr != null && idStr.equals("add_new")) {
            pushEditView(-1);
            return;
        }

        var idx = (idStr as String).toNumber();
        if (idx != null && idx >= 0 && idx < _store.getReminders().size()) {
            showReminderActions(idx);
        }
    }

    //! Raw key handler — receives keys that Menu2 does not consume internally.
    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();
        System.println("MenuDelegate.onKey: key=" + key);

        if (key == WatchUi.KEY_START) {
            System.println("MenuDelegate: KEY_START — launching add flow");
            pushEditView(-1);
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            return false;
        }

        return false;
    }

    //! Menu2 calls onBack() when Back key is pressed.
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    //! Menu2 calls onWrap() when navigating past the end of the menu.
    function onWrap(key as WatchUi.Key) as Boolean {
        return true;
    }

    //! Show the Activate/Deactivate + Edit + Remove sub-menu.
    hidden function showReminderActions(index as Number) as Void {
        System.println("MenuDelegate: showing actions for index=" + index);
        var actionsView = new ReminderActionsView(_store, index);
        var actionsDelegate = new ReminderActionsDelegate(_store, index, self);
        WatchUi.pushView(actionsView, actionsDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function rebuildAndShow() as Void {
        var newView = new ReminderMenuView(_store);
        var newDelegate = new ReminderMenuDelegate(_store);
        WatchUi.switchToView(newView, newDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    function pushEditView(index as Number) as Void {
        System.println("pushEditView called, index=" + index);
        var ev = new ReminderEditView(_store, index);
        var ed = new ReminderEditDelegate2(ev);
        WatchUi.pushView(ev, ed, WatchUi.SLIDE_IMMEDIATE);
    }

    function removeReminder(index as Number) as Void {
        if (index >= 0 && index < _store.getReminders().size()) {
            _store.removeReminder(index);
            rebuildAndShow();
        }
    }

    function getStore() as ReminderStore {
        return _store;
    }
}

// ──────────────────────────────────────────────
//  Reminder actions sub-menu (Activate/Deactivate
//  + Edit + Remove) — shown on Start/Select.
// ──────────────────────────────────────────────

class ReminderActionsView extends WatchUi.Menu2 {

    function initialize(store as ReminderStore, index as Number) {
        Menu2.initialize({:title => "Reminder"});
        var reminders = store.getReminders();
        if (index < 0 || index >= reminders.size()) { return; }
        var r = reminders[index];

        var toggleLabel = r.enabled ? "Deactivate" : "Activate";
        addItem(new WatchUi.MenuItem(toggleLabel, null, "toggle", {}));
        addItem(new WatchUi.MenuItem("Edit", null, "edit", {}));
        addItem(new WatchUi.MenuItem("Remove", null, "remove", {}));
    }
}

class ReminderActionsDelegate extends WatchUi.Menu2InputDelegate {

    private var _store as ReminderStore;
    private var _index as Number;
    private var _menuDelegate as ReminderMenuDelegate;

    function initialize(store as ReminderStore,
                        index as Number,
                        menuDelegate as ReminderMenuDelegate) {
        Menu2InputDelegate.initialize();
        _store = store;
        _index = index;
        _menuDelegate = menuDelegate;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var idStr = item.getId() as String;
        System.println("ActionsDelegate.onSelect: " + idStr);

        if (idStr.equals("toggle")) {
            _store.toggleReminder(_index);
            _menuDelegate.rebuildAndShow();
        } else if (idStr.equals("edit")) {
            _menuDelegate.pushEditView(_index);
        } else if (idStr.equals("remove")) {
            _store.removeReminder(_index);
            _menuDelegate.rebuildAndShow();
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

// ──────────────────────────────────────────────
//  Edit view delegate — bridges ReminderEditView
//  with the ReminderMenuDelegate
// ──────────────────────────────────────────────

class ReminderEditDelegate2 extends WatchUi.BehaviorDelegate {

    private var _ev as ReminderEditView;

    function initialize(ev as ReminderEditView) {
        BehaviorDelegate.initialize();
        _ev = ev;
    }

    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            _ev.onUp();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _ev.onDown();
            return true;
        }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _ev.onSelect();
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            _ev.onMenu();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            return _ev.onBackPressed();
        }
        return false;
    }

}
