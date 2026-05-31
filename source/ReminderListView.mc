import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

//! Main list view
class ReminderListView extends WatchUi.View {

    private var _store as ReminderStore?;
    private var _scrollIndex as Number = 0;
    private var _maxVisible as Number = 0;
    private var _itemHeight as Number = 0;
    private var _headerHeight as Number = 0;

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
        var width = dc.getWidth();
        var height = dc.getHeight();

        _headerHeight = 35;
        _itemHeight = 40;
        _maxVisible = (height - _headerHeight - 20) / _itemHeight;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, width, height);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
        dc.fillRectangle(0, 0, width, _headerHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLUE);
        dc.drawText(width / 2, _headerHeight / 2, Graphics.FONT_MEDIUM, "Custom Reminders", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var store = _store;
        if (store != null) {
            var reminders = store.getReminders();
            var y = _headerHeight + 5;

            if (reminders.size() == 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, height / 2, Graphics.FONT_SMALL, "No reminders", Graphics.TEXT_JUSTIFY_CENTER);
                dc.drawText(width / 2, height / 2 + 25, Graphics.FONT_TINY, "MENU to add", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                var end = _scrollIndex + _maxVisible;
                if (end > reminders.size()) { end = reminders.size(); }

                for (var i = _scrollIndex; i < end; i++) {
                    var r = reminders[i];
                    var itemY = y + ((i - _scrollIndex) * _itemHeight);

                    if ((i - _scrollIndex) % 2 == 0) {
                        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                        dc.fillRectangle(5, itemY, width - 10, _itemHeight - 3);
                    }

                    if (r.enabled) {
                        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(15, itemY + 12, Graphics.FONT_SMALL, "ON", Graphics.TEXT_JUSTIFY_LEFT);
                    } else {
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(15, itemY + 12, Graphics.FONT_SMALL, "OFF", Graphics.TEXT_JUSTIFY_LEFT);
                    }

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(55, itemY + 12, Graphics.FONT_SMALL, r.getDisplayText(20), Graphics.TEXT_JUSTIFY_LEFT);

                    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(55, itemY + 28, Graphics.FONT_TINY, r.getScheduleDescription(), Graphics.TEXT_JUSTIFY_LEFT);
                }
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height - 15, Graphics.FONT_TINY, "SELECT:Toggle MENU:Add", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onMenu() as Void {
        var store = _store;
        if (store != null) {
            var editView = new ReminderEditView(store, -1);
            var editDelegate = new ReminderEditDelegate(self);
            WatchUi.pushView(editView, editDelegate, WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function onSelect() as Void {
        var store = _store;
        if (store != null) {
            var idx = _scrollIndex;
            if (idx >= 0 && idx < store.getReminders().size()) {
                store.toggleReminder(idx);
                WatchUi.requestUpdate();
            }
        }
    }

    function onUp() as Void {
        if (_scrollIndex > 0) {
            _scrollIndex--;
            WatchUi.requestUpdate();
        }
    }

    function onDown() as Void {
        var store = _store;
        if (store != null) {
            if (_scrollIndex + _maxVisible < store.getReminders().size()) {
                _scrollIndex++;
                WatchUi.requestUpdate();
            }
        }
    }

    function refresh() as Void {
        var store = _store;
        if (store != null) {
            store.loadFromStorage();
        }
        WatchUi.requestUpdate();
    }
}

//! Delegate for the edit view that refreshes list on return
class ReminderEditDelegate extends WatchUi.BehaviorDelegate {

    private var _listView as ReminderListView;

    function initialize(listView as ReminderListView) {
        BehaviorDelegate.initialize();
        _listView = listView;
    }

    function onViewUncovered(info as WatchUi.ViewInfo) as Void {
        _listView.refresh();
    }
}
