import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;

//! Wizard view for adding/editing reminders with clean spacing
class ReminderEditView extends WatchUi.View {

    const STEP_TEXT     = 0;
    const STEP_TYPE     = 1;
    const STEP_INTERVAL = 2;
    const STEP_TIME     = 3;
    const STEP_ENABLED  = 4;
    const STEP_CONFIRM  = 5;

    const CHARS = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,!?-_";
    const INTERVALS = [300, 900, 1800, 3600, 7200];
    const INTERVAL_LABELS = ["5 min", "15 min", "30 min", "1 hour", "2 hours"];

    const TYPE_INTERVAL = 0;
    const TYPE_TIME = 1;

    private var _store    as ReminderStore;
    private var _editIdx  as Number;
    private var _step     as Number;

    private var _text      as String = "";
    private var _type      as Number = 0;
    private var _interval  as Number = 3600;
    private var _enabled   as Boolean = true;
    private var _charIdx   as Number = 0;
    private var _hour      as Number = 14;
    private var _minute    as Number = 0;
    private var _intIdx    as Number = 3;

    // Layout
    private var _isSmall  as Boolean = false;
    private var _marginT  as Number = 0;
    private var _marginB  as Number = 0;
    private var _contentY as Number = 0;
    private var _rowGap   as Number = 0;

    function initialize(store as ReminderStore, editIdx as Number) {
        View.initialize();
        _store  = store;
        _editIdx = editIdx;
        _step   = STEP_TEXT;

        if (editIdx >= 0) {
            var rem = _store.getReminders();
            if (editIdx < rem.size()) {
                var r = rem[editIdx];
                _text    = r.text;
                _type    = r.type;
                _interval = r.interval;
                _enabled  = r.enabled;
                for (var i = 0; i < INTERVALS.size(); i++) {
                    if (INTERVALS[i] == _interval) { _intIdx = i; break; }
                }
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        _isSmall = ((w < h ? w : h) <= 240);
        var isRound = (w == h);

        _marginT = _isSmall ? 35 : 15;
        _marginB = _isSmall ? 42 : 20;
        _rowGap  = _isSmall ? 20 : 32;
        _contentY = _marginT + 24;

        // ── Background ──
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, w, h);

        // ── Step title ──
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, _marginT + 2, Graphics.FONT_TINY, getStepTitle(),
            Graphics.TEXT_JUSTIFY_CENTER);

        // ── Step content ──
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        if      (_step == STEP_TEXT)     { drawTextInput(dc, w); }
        else if (_step == STEP_TYPE)     { drawTypeSelect(dc, w); }
        else if (_step == STEP_INTERVAL) { drawIntervalSelect(dc, w); }
        else if (_step == STEP_TIME)     { drawTimeSelect(dc, w); }
        else if (_step == STEP_ENABLED)  { drawEnabledToggle(dc, w); }
        else if (_step == STEP_CONFIRM)  { drawConfirm(dc, w); }


    }

    hidden function drawTextInput(dc as Graphics.Dc, w as Number) as Void {
        var label = _text.length() == 0 ? "(empty)" : _text;
        dc.drawText(w / 2, _contentY, Graphics.FONT_TINY, label,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (_charIdx < CHARS.length()) {
            var ch = CHARS.substring(_charIdx, _charIdx + 1);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, _contentY + 22, Graphics.FONT_SMALL, ch,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function drawTypeSelect(dc as Graphics.Dc, w as Number) as Void {
        var iLabel = (_type == TYPE_INTERVAL ? "► " : "  ") + "Interval";
        var tLabel = (_type == TYPE_TIME    ? "► " : "  ") + "Time of Day";
        dc.drawText(w / 2, _contentY, Graphics.FONT_TINY, iLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, _contentY + _rowGap, Graphics.FONT_TINY, tLabel, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawIntervalSelect(dc as Graphics.Dc, w as Number) as Void {
        var start = 0;
        var visible = 3;
        if (_intIdx >= visible) { start = _intIdx - (visible - 1); }

        for (var i = start; i < INTERVAL_LABELS.size(); i++) {
            var ry = _contentY + (i - start) * _rowGap;
            if (ry > dc.getHeight() - _marginB - 15) { break; }
            dc.setColor(
                i == _intIdx ? Graphics.COLOR_GREEN : Graphics.COLOR_WHITE,
                Graphics.COLOR_TRANSPARENT);
            var prefix = i == _intIdx ? "► " : "  ";
            dc.drawText(w / 2, ry, Graphics.FONT_TINY, prefix + INTERVAL_LABELS[i],
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function drawTimeSelect(dc as Graphics.Dc, w as Number) as Void {
        dc.drawText(w / 2, _contentY, Graphics.FONT_MEDIUM,
            formatTime(_hour, _minute), Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawEnabledToggle(dc as Graphics.Dc, w as Number) as Void {
        var s = _enabled ? "Enabled" : "Disabled";
        dc.drawText(w / 2, _contentY, Graphics.FONT_SMALL, s, Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawConfirm(dc as Graphics.Dc, w as Number) as Void {
        dc.drawText(w / 2, _contentY, Graphics.FONT_TINY, "Save Reminder?",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, _contentY + _rowGap,       Graphics.FONT_TINY, _text,
            Graphics.TEXT_JUSTIFY_CENTER);
        var sched = (_type == TYPE_INTERVAL)
            ? "Every " + INTERVAL_LABELS[_intIdx]
            : formatTime(_hour, _minute);
        dc.drawText(w / 2, _contentY + _rowGap + 12,  Graphics.FONT_TINY, sched,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function formatTime(h as Number, m as Number) as String {
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
    }

    hidden function getStepTitle() as String {
        var steps = ["Step 1/5: Text", "Step 2/5: Type",
                     "Step 3/5: Interval", "Step 3/5: Time",
                     "Step 4/5: Enable", "Step 5/5: Confirm"];
        if (_step < steps.size()) { return steps[_step]; }
        return "";
    }

    // ── Input handlers ──

    function onMenu() as Void {
        if (_step == STEP_TEXT || _step == STEP_CONFIRM) { nextStep(); }
    }

    function onSelect() as Void {
        if      (_step == STEP_TEXT) {
            if (_charIdx < CHARS.length()) {
                _text += CHARS.substring(_charIdx, _charIdx + 1);
            }
        } else if (_step == STEP_TYPE     ) { nextStep(); }
        else if (_step == STEP_INTERVAL   ) { nextStep(); }
        else if (_step == STEP_TIME       ) { nextStep(); }
        else if (_step == STEP_ENABLED    ) { _enabled = !_enabled; }
        else if (_step == STEP_CONFIRM    ) { save(); }
    }

    function onUp() as Void {
        if      (_step == STEP_TEXT      ) { if (_charIdx > 0) { _charIdx--; } }
        else if (_step == STEP_TYPE      ) { _type = TYPE_INTERVAL; }
        else if (_step == STEP_INTERVAL  ) {
            if (_intIdx > 0) { _intIdx--; _interval = INTERVALS[_intIdx]; }
        } else if (_step == STEP_TIME    ) {
            if (_charIdx == 0) { _hour   = (_hour   + 1) % 24; }
            else               { _minute = (_minute + 5) % 60; }
        }
        WatchUi.requestUpdate();
    }

    function onDown() as Void {
        if      (_step == STEP_TEXT      ) {
            if (_charIdx < CHARS.length() - 1) { _charIdx++; }
        } else if (_step == STEP_TYPE      ) { _type = TYPE_TIME; }
        else if (_step == STEP_INTERVAL  ) {
            if (_intIdx < INTERVALS.size() - 1) { _intIdx++; _interval = INTERVALS[_intIdx]; }
        } else if (_step == STEP_TIME    ) {
            if (_charIdx == 0) { _hour   = (_hour   + 23) % 24; }
            else               { _minute = (_minute + 55) % 60; }
        }
        WatchUi.requestUpdate();
    }

    function onBackPressed() as Boolean {
        if      (_step == STEP_TEXT) {
            if (_text.length() > 0) {
                _text = _text.substring(0, _text.length() - 1);
            } else {
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                return false;
            }
        } else if (_step == STEP_TYPE     ) { _step = STEP_TEXT; }
        else if (_step == STEP_INTERVAL ||
                 _step == STEP_TIME      ) { _step = STEP_TYPE; }
        else if (_step == STEP_ENABLED   ) {
            _step = (_type == TYPE_INTERVAL) ? STEP_INTERVAL : STEP_TIME;
        } else if (_step == STEP_CONFIRM ) { _step = STEP_ENABLED; }
        else { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); return false; }
        WatchUi.requestUpdate();
        return true;
    }

    hidden function nextStep() as Void {
        _step++;
        if      (_step == STEP_TIME     && _type == TYPE_INTERVAL) { _step = STEP_ENABLED; }
        else if (_step == STEP_INTERVAL && _type == TYPE_TIME)     { _step = STEP_TIME; }
        WatchUi.requestUpdate();
    }

    hidden function save() as Void {
        if (_text.length() == 0) { return; }
        if (!_store.canAddMore() && _editIdx < 0) { return; }

        var r = new Reminder();
        r.text     = _text;
        r.type     = _type;
        r.interval = _interval;
        r.time     = formatTime(_hour, _minute);
        r.enabled  = _enabled;

        if (_editIdx >= 0) {
            var rems = _store.getReminders();
            if (_editIdx < rems.size()) {
                r.id = rems[_editIdx].id;
                r.lastTriggered = rems[_editIdx].lastTriggered;
                _store.updateReminder(r);
            }
        } else {
            r.id = "r_" + System.getTimer();
            _store.addReminder(r);
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
