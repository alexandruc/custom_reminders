import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Main list view using Menu2 with ToggleMenuItems for each reminder.
class ReminderMenuView extends WatchUi.Menu2 {

    private var _store as ReminderStore;

    function initialize(store as ReminderStore) {
        Menu2.initialize({:title => "Reminders"});
        _store = store;
        buildItems();
    }

    //! (Re)build all menu items from the store
    function buildItems() as Void {
        // Clear existing items (not directly supported, so recreate)
        // Instead we rebuild by removing all and re-adding.
        // Menu2 doesn't have removeItem(), so we just add items fresh.
        // Since this is called from initialize, the menu is empty.
        var reminders = _store.getReminders();
        for (var i = 0; i < reminders.size(); i++) {
            var r = reminders[i];
            var label = r.getDisplayText(20);
            var item = new WatchUi.ToggleMenuItem(
                label,
                null,
                i.toString(),
                r.enabled,
                {}
            );
            addItem(item);
        }
        // Add "Add new" item at the end
        addItem(new WatchUi.MenuItem(
            "+ Add new",
            null,
            "add_new",
            {}
        ));
    }

    //! Rebuild menu items after data changes (called from delegate)
    function refresh() as Void {
        // Menu2 doesn't support removing/replacing items, so we create
        // a new instance and replace the view on the stack.
        // This is handled by the delegate calling pushView with a new instance.
    }
}

//! Delegate for ReminderMenuView
class ReminderMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _store as ReminderStore;
    private var _lastItemId as String?;

    function initialize(store as ReminderStore) {
        Menu2InputDelegate.initialize();
        _store = store;
        _lastItemId = null;
    }

    //! Toggle a reminder on/off
    function onToggle(item as WatchUi.ToggleMenuItem) as Void {
        var idStr = item.getId() as String;
        var idx = idStr.toNumber();
        if (idx != null && idx >= 0 && idx < _store.getReminders().size()) {
            _store.toggleReminder(idx);
            _lastItemId = idStr;
        }
    }

    //! Handle selection of a menu item (only fires for non-toggle items like "Add new")
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == "add_new") {
            pushEditView(-1);
        }
        // ToggleMenuItems are handled by onToggle() — ignore them here
    }

    //! Handle Menu button — show context menu for the last-interacted reminder
    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_MENU) {
            // Show context menu (Edit/Remove) — use last toggled item or default to 0
            var reminders = _store.getReminders();
            if (reminders.size() > 0) {
                var idx = 0;
                if (_lastItemId != null) {
                    var parsed = _lastItemId.toNumber();
                    if (parsed != null && parsed >= 0 && parsed < reminders.size()) {
                        idx = parsed;
                    }
                }
                var ctxView = new ReminderContextMenuView2(self, idx);
                var ctxDelegate = new ReminderContextMenuDelegate2(ctxView, self, idx);
                WatchUi.pushView(ctxView, ctxDelegate, WatchUi.SLIDE_IMMEDIATE);
            }
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            return false;  // Let Menu2 handle back navigation
        }

        return false;
    }

    //! Return to the main menu after data changes
    function rebuildAndShow() as Void {
        var newView = new ReminderMenuView(_store);
        var newDelegate = new ReminderMenuDelegate(_store);
        WatchUi.switchToView(newView, newDelegate, WatchUi.SLIDE_IMMEDIATE);
    }

    //! Push the edit wizard
    function pushEditView(index as Number) as Void {
        System.println("pushEditView called, index=" + index);
        var ev = new ReminderEditView(_store, index);
        var ed = new ReminderEditDelegate2(ev, self);
        WatchUi.pushView(ev, ed, WatchUi.SLIDE_IMMEDIATE);
    }

    //! Remove a reminder by index
    function removeReminder(index as Number) as Void {
        if (index >= 0 && index < _store.getReminders().size()) {
            _store.removeReminder(index);
            rebuildAndShow();
        }
    }

    //! Get the reminder store
    function getStore() as ReminderStore {
        return _store;
    }
}

// ──────────────────────────────────────────────
//  Context menu view (Edit / Remove)
// ──────────────────────────────────────────────

class ReminderContextMenuView2 extends WatchUi.View {

    private var _delegate as ReminderMenuDelegate;
    private var _index    as Number;
    private var _selOption as Number = 0;

    const OPTIONS = ["Edit", "Remove"];

    function initialize(delegate as ReminderMenuDelegate, index as Number) {
        View.initialize();
        _delegate = delegate;
        _index    = index;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        // Show which reminder this is for
        var reminders = _delegate.getStore().getReminders();
        var label = (_index >= 0 && _index < reminders.size())
            ? reminders[_index].getDisplayText(20) : "";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.12, Graphics.FONT_TINY, label,
            Graphics.TEXT_JUSTIFY_CENTER);

        var startY = h * 0.25;
        var rowH = 40;

        for (var i = 0; i < OPTIONS.size(); i++) {
            var iy = startY + i * rowH;
            var isSel = (i == _selOption);

            if (isSel) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            } else if (i % 2 == 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            }
            dc.fillRectangle(5, iy, w - 10, rowH - 2);

            dc.setColor(
                isSel ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE,
                Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, iy + rowH / 2, Graphics.FONT_SMALL, OPTIONS[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function moveUp() as Void {
        _selOption = 0;
        WatchUi.requestUpdate();
    }

    function moveDown() as Void {
        _selOption = 1;
        WatchUi.requestUpdate();
    }

    function getSelectedOption() as Number {
        return _selOption;
    }

    function getDelegate() as ReminderMenuDelegate {
        return _delegate;
    }

    function getReminderIndex() as Number {
        return _index;
    }
}

// ──────────────────────────────────────────────
//  Context menu delegate
// ──────────────────────────────────────────────

class ReminderContextMenuDelegate2 extends WatchUi.BehaviorDelegate {

    private var _ctxView  as ReminderContextMenuView2;
    private var _menuDelegate as ReminderMenuDelegate;
    private var _index    as Number;

    function initialize(ctxView as ReminderContextMenuView2,
                        menuDelegate as ReminderMenuDelegate,
                        index as Number) {
        BehaviorDelegate.initialize();
        _ctxView  = ctxView;
        _menuDelegate = menuDelegate;
        _index    = index;
    }

    function onKey(keyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            _ctxView.moveUp();
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _ctxView.moveDown();
            return true;
        }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            doAction();
            return true;
        }
        if (key == WatchUi.KEY_MENU) {
            doAction();
            return true;
        }
        if (key == WatchUi.KEY_ESC) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }
        return false;
    }

    hidden function doAction() as Void {
        var opt = _ctxView.getSelectedOption();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (opt == 0) {
            // Edit
            _menuDelegate.pushEditView(_index);
        } else {
            // Remove
            _menuDelegate.removeReminder(_index);
        }
    }
}

// ──────────────────────────────────────────────
//  Edit view delegate — bridges ReminderEditView
//  with the ReminderMenuDelegate
// ──────────────────────────────────────────────

class ReminderEditDelegate2 extends WatchUi.BehaviorDelegate {

    private var _ev as ReminderEditView;
    private var _menuDelegate as ReminderMenuDelegate;

    function initialize(ev as ReminderEditView, menuDelegate as ReminderMenuDelegate) {
        BehaviorDelegate.initialize();
        _ev = ev;
        _menuDelegate = menuDelegate;
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

    function onViewUncovered(info as WatchUi.ViewInfo) as Void {
        // After returning from edit, rebuild the menu view
        _menuDelegate.rebuildAndShow();
    }
}
