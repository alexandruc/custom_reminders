import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

//! Main list view with clean, non-overlapping layout
class ReminderListView extends WatchUi.View {

    private var _store as ReminderStore?;
    private var _scrollIndex as Number = 0;
    private var _itemHeight as Number = 0;
    private var _headerHeight as Number = 0;
    private var _contentTop as Number = 0;
    private var _contentBottom as Number = 0;
    private var _maxVisible as Number = 0;
    private var _isSmall as Boolean = false;

    function initialize() {
        View.initialize();
        _store = null;
    }

    function onShow() as Void {
        _store = new ReminderStore();
        _store.loadFromStorage();
        _scrollIndex = 0;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var min = w < h ? w : h;
        _isSmall = (min <= 240);
        var isRound = (w == h);

        // Margins keep content away from circular bezel
        var marginTop  = _isSmall ? 35 : 8;
        var marginBot  = _isSmall ? 45 : 20;
        var marginSide = _isSmall ? 15 : 5;

        // Item height must be tall enough to avoid text overlap
        _headerHeight    = _isSmall ? 20 : 28;
        _itemHeight      = _isSmall ? 28 : 36;

        _contentTop    = marginTop + _headerHeight + 2;
        _contentBottom = h - marginBot - 2;
        var usableH    = _contentBottom - _contentTop;
        _maxVisible    = usableH / _itemHeight;

        // ── Background ──
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        // ── Header bar (blue fill from top down past title) ──
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(0, 0, w, marginTop + _headerHeight);

        // Reminders title centred in the blue area
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLUE);
        dc.drawText(w / 2, (marginTop + _headerHeight) / 2, Graphics.FONT_TINY, "Reminders",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Main content ──
        var store = _store;
        if (store == null) { return; }

        var reminders = store.getReminders();

        if (reminders.size() == 0) {
            // Centered empty state
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var cy = (marginTop + h - marginBot) / 2;
            dc.drawText(w / 2, cy - 10, Graphics.FONT_TINY, "No reminders",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, cy + 8,  Graphics.FONT_TINY,  "Menu to add",
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // ── List items ──
        var end = _scrollIndex + _maxVisible;
        if (end > reminders.size()) { end = reminders.size(); }

        for (var i = _scrollIndex; i < end; i++) {
            var r  = reminders[i];
            var iy = _contentTop + (i - _scrollIndex) * _itemHeight;

            // Alternating row fill
            if ((i - _scrollIndex) % 2 == 0) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(marginSide, iy, w - 2 * marginSide, _itemHeight - 2);
            }

            // ON/OFF (left side, vertically centred)
            var cyOff = iy + _itemHeight / 2 - 3;
            if (r.enabled) {
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.drawText(marginSide + 2, cyOff, Graphics.FONT_TINY, "ON",
                    Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(marginSide + 2, cyOff, Graphics.FONT_TINY, "OFF",
                    Graphics.TEXT_JUSTIFY_LEFT);
            }

            // Reminder text (offset right of ON/OFF)
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(marginSide + 22, cyOff, Graphics.FONT_TINY,
                r.getDisplayText(16), Graphics.TEXT_JUSTIFY_LEFT);

            // Schedule description (below reminder text)
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(marginSide + 22, cyOff + 9, Graphics.FONT_TINY,
                r.getScheduleDescription(), Graphics.TEXT_JUSTIFY_LEFT);
        }


    }

    function onMenu() as Void {
        var store = _store;
        if (store != null) {
            var ev = new ReminderEditView(store, -1);
            var ed = new ReminderEditDelegate(ev, self);
            WatchUi.pushView(ev, ed, WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onSelect() as Void {
        var store = _store;
        if (store == null) { return; }
        if (_scrollIndex >= 0 && _scrollIndex < store.getReminders().size()) {
            store.toggleReminder(_scrollIndex);
            WatchUi.requestUpdate();
        }
    }

    function onUp() as Void {
        if (_scrollIndex > 0) { _scrollIndex--; WatchUi.requestUpdate(); }
    }

    function onDown() as Void {
        var store = _store;
        if (store == null) { return; }
        if (_scrollIndex + _maxVisible < store.getReminders().size()) {
            _scrollIndex++;
            WatchUi.requestUpdate();
        }
    }

    function refresh() as Void {
        var store = _store;
        if (store != null) { store.loadFromStorage(); }
        WatchUi.requestUpdate();
    }
}

//! Delegate that forwards button events to the edit view
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
