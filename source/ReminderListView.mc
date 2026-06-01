import Toybox.Lang;
import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Main list view showing reminders with a cursor, toggle on Select,
//! "Add new" button at end, and context menu (Edit/Remove) on Menu.
class ReminderListView extends WatchUi.View {

    private var _store        as ReminderStore?;
    private var _selIdx       as Number = 0;   // cursor within [0 .. reminders.size()]
    private var _scrollOfs    as Number = 0;   // first visible item index
    private var _itemHeight   as Number = 0;
    private var _headerHeight as Number = 0;
    private var _contentTop   as Number = 0;
    private var _contentBot   as Number = 0;
    private var _maxVisible   as Number = 0;
    private var _marginSide   as Number = 0;
    private var _marginTop    as Number = 0;
    private var _marginBot    as Number = 0;
    private var _isSmall      as Boolean = false;

    function initialize() {
        View.initialize();
        _store = null;
    }

    function onShow() as Void {
        var app = Application.getApp() as CustomRemindersApp;
        _store = app.getStore();
        _selIdx = 0;
        _scrollOfs = 0;
    }

    // ── layout helpers ──

    hidden function setupLayout(dc as Graphics.Dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var min = w < h ? w : h;
        _isSmall = (min <= 240);

        _marginTop  = _isSmall ? 35 : 8;
        _marginBot  = _isSmall ? 40 : 18;
        _marginSide = _isSmall ? 15 : 5;
        _headerHeight = _isSmall ? 20 : 28;
        _itemHeight   = _isSmall ? 30 : 40;

        _contentTop = _marginTop + _headerHeight + 2;
        _contentBot = h - _marginBot - 2;
        var usable  = _contentBot - _contentTop;
        _maxVisible = usable / _itemHeight;
    }

    // ── draw ──

    function onUpdate(dc as Graphics.Dc) as Void {
        setupLayout(dc);
        var w = dc.getWidth();
        var h = dc.getHeight();

        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        // Header bar
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(0, 0, w, _marginTop + _headerHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLUE);
        dc.drawText(w / 2, (_marginTop + _headerHeight) / 2, Graphics.FONT_TINY,
            "Reminders",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var store = _store;
        if (store == null) { return; }
        var reminders = store.getReminders();
        var total = reminders.size() + 1;     // reminders + "Add new"

        // Clamp cursor within valid range
        if (_selIdx >= total) { _selIdx = total - 1; }
        if (_selIdx < 0) { _selIdx = 0; }

        // Ensure cursor is visible
        if (_selIdx < _scrollOfs) { _scrollOfs = _selIdx; }
        if (_selIdx >= _scrollOfs + _maxVisible) {
            _scrollOfs = _selIdx - _maxVisible + 1;
            if (_scrollOfs < 0) { _scrollOfs = 0; }
        }

        // If total items fit on one screen, center the list vertically
        var startY = _contentTop;
        if (total <= _maxVisible) {
            // Centre the block
            var blockH = total * _itemHeight;
            startY = _contentTop + ((_contentBot - _contentTop - blockH) / 2);
            _scrollOfs = 0;
        }

        // Draw each visible item
        var end = _scrollOfs + _maxVisible;
        if (end > total) { end = total; }

        for (var i = _scrollOfs; i < end; i++) {
            var iy = startY + (i - _scrollOfs) * _itemHeight;
            var isCursor = (i == _selIdx);

            if (i < reminders.size()) {
                drawReminderItem(dc, w, i, iy, isCursor, reminders[i]);
            } else {
                drawAddNewItem(dc, w, iy, isCursor);
            }
        }
    }

    hidden function drawReminderItem(dc as Graphics.Dc, w as Number,
                                      idx as Number, y as Number,
                                      isCursor as Boolean, r as Reminder) as Void {
        // Row background
        if (isCursor) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRectangle(_marginSide, y, w - 2 * _marginSide, _itemHeight - 2);
        } else if (idx % 2 == 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            dc.fillRectangle(_marginSide, y, w - 2 * _marginSide, _itemHeight - 2);
        }

        // ON/OFF (left side)
        var cy = y + _itemHeight / 2 - 3;
        if (r.enabled) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_marginSide + 2, cy, Graphics.FONT_TINY, "ON",
                Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_marginSide + 2, cy, Graphics.FONT_TINY, "OFF",
                Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Reminder text
        dc.setColor(isCursor ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(_marginSide + 22, cy, Graphics.FONT_TINY,
            r.getDisplayText(16), Graphics.TEXT_JUSTIFY_LEFT);

        // Schedule description
        dc.setColor(isCursor ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(_marginSide + 22, cy + 9, Graphics.FONT_TINY,
            r.getScheduleDescription(), Graphics.TEXT_JUSTIFY_LEFT);
    }

    hidden function drawAddNewItem(dc as Graphics.Dc, w as Number,
                                    y as Number, isCursor as Boolean) as Void {
        // Distinct button style: blue background when cursor, dark gray otherwise
        if (isCursor) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        } else {
            dc.setColor(0x333333, 0x333333);
        }
        dc.fillRectangle(_marginSide, y, w - 2 * _marginSide, _itemHeight - 2);

        // Dashed top line to separate from reminders
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_marginSide + 4, y, w - _marginSide - 4, y);

        // "+ Add new" centered
        var cy = y + _itemHeight / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, cy, Graphics.FONT_TINY, "+ Add new",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ── input handlers ──

    function onSelect() as Void {
        var store = _store;
        if (store == null) { return; }
        var reminders = store.getReminders();

        if (_selIdx < reminders.size()) {
            // Toggle reminder
            store.toggleReminder(_selIdx);
            WatchUi.requestUpdate();
        } else {
            // Open add-new wizard
            pushEditView(-1);
        }
    }

    function onMenu() as Void {
        System.println("onMenu called");
        var store = _store;
        if (store == null) { System.println("store is null"); return; }
        var reminders = store.getReminders();
        System.println("reminders.size=" + reminders.size() + " selIdx=" + _selIdx);

        if (_selIdx < reminders.size()) {
            System.println("Showing context menu for reminder " + _selIdx);
            var ctxView  = new ReminderContextMenuView(self, _selIdx);
            var ctxDelegate = new ReminderContextMenuDelegate(ctxView, self, _selIdx);
            WatchUi.pushView(ctxView, ctxDelegate, WatchUi.SLIDE_IMMEDIATE);
            System.println("Context menu pushed");
        } else {
            System.println("Opening add-new wizard");
            pushEditView(-1);
        }
    }

    function onUp() as Void {
        if (_selIdx > 0) {
            _selIdx--;
            WatchUi.requestUpdate();
        }
    }

    function onDown() as Void {
        var store = _store;
        if (store == null) { return; }
        var total = store.getReminders().size() + 1;  // reminders + "Add new"
        if (_selIdx < total - 1) {
            _selIdx++;
            WatchUi.requestUpdate();
        }
    }

    // ── public helpers called by delegate / context menu ──

    function pushEditView(index as Number) as Void {
        System.println("pushEditView called, index=" + index);
        var store = _store;
        if (store == null) { System.println("store is null"); return; }
        System.println("Creating ReminderEditView");
        var ev = new ReminderEditView(store, index);
        var ed = new ReminderEditDelegate(ev, self);
        System.println("Pushing edit view");
        WatchUi.pushView(ev, ed, WatchUi.SLIDE_IMMEDIATE);
        System.println("pushEditView done");
    }

    function removeReminder(index as Number) as Void {
        var store = _store;
        if (store == null) { return; }
        store.removeReminder(index);
        var total = store.getReminders().size() + 1;
        if (_selIdx >= total) { _selIdx = total - 1; }
        if (_selIdx < 0) { _selIdx = 0; }
        WatchUi.requestUpdate();
    }

    function refresh() as Void {
        var store = _store;
        if (store != null) { store.loadFromStorage(); }
        var total = (_store != null) ? _store.getReminders().size() + 1 : 1;
        if (_selIdx >= total) { _selIdx = total - 1; }
        if (_selIdx < 0) { _selIdx = 0; }
        WatchUi.requestUpdate();
    }
}

// ──────────────────────────────────────────────
//  Context menu view (Edit / Remove)
//  Custom drawn because WatchUi.Menu is not
//  available in SDK 3.3 (API 3.1.0).
// ──────────────────────────────────────────────

class ReminderContextMenuView extends WatchUi.View {

    private var _listView as ReminderListView;
    private var _index    as Number;
    private var _selOption as Number = 0;  // 0 = Edit, 1 = Remove

    const OPTIONS = ["Edit", "Remove"];

    function initialize(listView as ReminderListView, index as Number) {
        View.initialize();
        _listView = listView;
        _index    = index;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isSmall = ((w < h ? w : h) <= 240);

        var marginT = isSmall ? 35 : 15;
        var marginB = isSmall ? 40 : 18;
        var marginX = isSmall ? 15 : 5;
        var rowH    = isSmall ? 30 : 40;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        // Title
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, marginT + 2, Graphics.FONT_TINY, "Options",
            Graphics.TEXT_JUSTIFY_CENTER);

        var startY = marginT + 26;
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
            dc.fillRectangle(marginX, iy, w - 2 * marginX, rowH - 2);

            dc.setColor(
                isSel ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE,
                Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, iy + rowH / 2, Graphics.FONT_SMALL, OPTIONS[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Called by delegate
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

    function getListView() as ReminderListView {
        return _listView;
    }

    function getReminderIndex() as Number {
        return _index;
    }
}

// ──────────────────────────────────────────────
//  Context menu delegate
// ──────────────────────────────────────────────

class ReminderContextMenuDelegate extends WatchUi.BehaviorDelegate {

    private var _ctxView  as ReminderContextMenuView;
    private var _listView as ReminderListView;
    private var _index    as Number;

    function initialize(ctxView as ReminderContextMenuView,
                        listView as ReminderListView,
                        index as Number) {
        BehaviorDelegate.initialize();
        _ctxView  = ctxView;
        _listView = listView;
        _index    = index;
    }

    function onSelect() as Boolean {
        var opt = _ctxView.getSelectedOption();
        if (opt == 0) {
            // Edit
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            _listView.pushEditView(_index);
        } else {
            // Remove
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            _listView.removeReminder(_index);
        }
        return true;
    }

    function onMenu() as Boolean {
        // Menu on context menu = same as Select (Edit)
        return onSelect();
    }

    function onUp() as Boolean {
        _ctxView.moveUp();
        return true;
    }

    function onDown() as Boolean {
        _ctxView.moveDown();
        return true;
    }

    function onBackPressed() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

// ──────────────────────────────────────────────
//  Delegate that forwards button events to the
//  ReminderEditView while it is active.
// ──────────────────────────────────────────────

class ReminderEditDelegate extends WatchUi.BehaviorDelegate {

    private var _ev as ReminderEditView;
    private var _lv as ReminderListView;

    function initialize(ev as ReminderEditView, lv as ReminderListView) {
        BehaviorDelegate.initialize();
        _ev = ev;
        _lv = lv;
    }

    function onSelect() as Boolean        { _ev.onSelect();      return true; }
    function onMenu()   as Boolean        { _ev.onMenu();        return true; }
    function onUp()     as Boolean        { _ev.onUp();          return true; }
    function onDown()   as Boolean        { _ev.onDown();        return true; }
    function onBackPressed() as Boolean   { return _ev.onBackPressed(); }

    function onViewUncovered(info as WatchUi.ViewInfo) as Void {
        _lv.refresh();
    }
}
