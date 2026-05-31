import Toybox.Application.Storage;
import Toybox.Lang;

//! Store for managing reminders with persistence
class ReminderStore {

    private var _reminders as Array<Reminder>;
    const MAX_REMINDERS = 20;
    const STORAGE_KEY = "reminders";

    function initialize() {
        _reminders = [];
    }

    function getReminders() as Array<Reminder> {
        return _reminders;
    }

    function getEnabledReminders() as Array<Reminder> {
        var enabled = [];
        for (var i = 0; i < _reminders.size(); i++) {
            if (_reminders[i].enabled) {
                enabled.add(_reminders[i]);
            }
        }
        return enabled;
    }

    function addReminder(reminder as Reminder) as Boolean {
        if (_reminders.size() >= MAX_REMINDERS) {
            return false;
        }
        _reminders.add(reminder);
        saveToStorage();
        return true;
    }

    function updateReminder(reminder as Reminder) as Boolean {
        for (var i = 0; i < _reminders.size(); i++) {
            if (_reminders[i].id == reminder.id) {
                _reminders[i] = reminder;
                saveToStorage();
                return true;
            }
        }
        return false;
    }

    function removeReminder(index as Number) as Boolean {
        if (index >= 0 && index < _reminders.size()) {
            var newReminders = [];
            for (var i = 0; i < _reminders.size(); i++) {
                if (i != index) {
                    newReminders.add(_reminders[i]);
                }
            }
            _reminders = newReminders;
            saveToStorage();
            return true;
        }
        return false;
    }

    function toggleReminder(index as Number) as Boolean {
        if (index >= 0 && index < _reminders.size()) {
            _reminders[index].enabled = !_reminders[index].enabled;
            saveToStorage();
            return true;
        }
        return false;
    }

    function count() as Number {
        return _reminders.size();
    }

    function canAddMore() as Boolean {
        return _reminders.size() < MAX_REMINDERS;
    }

    function saveToStorage() as Void {
        // Store reminder count and individual fields by index
        // Edge case: handle storage overflow by limiting stored fields
        try {
            Storage.setValue(STORAGE_KEY + "_count", _reminders.size());
        } catch (ex) {
            System.println("ReminderStore: Storage overflow - clearing old data");
            _reminders = [];
            return;
        }
        for (var i = 0; i < _reminders.size(); i++) {
            var r = _reminders[i];
            var prefix = STORAGE_KEY + "_" + i;
            Storage.setValue(prefix + "_id", r.id);
            Storage.setValue(prefix + "_text", r.text);
            Storage.setValue(prefix + "_type", r.type);
            Storage.setValue(prefix + "_interval", r.interval);
            Storage.setValue(prefix + "_time", r.time);
            Storage.setValue(prefix + "_enabled", r.enabled);
            Storage.setValue(prefix + "_lastTriggered", r.lastTriggered);
        }
    }

    function loadFromStorage() as Void {
        var cnt = Storage.getValue(STORAGE_KEY + "_count") as Number?;
        if (cnt == null) {
            return;
        }

        _reminders = [];
        for (var i = 0; i < cnt; i++) {
            var prefix = STORAGE_KEY + "_" + i;
            var reminder = new Reminder();
            reminder.id = Storage.getValue(prefix + "_id") as String;
            reminder.text = Storage.getValue(prefix + "_text") as String;
            reminder.type = Storage.getValue(prefix + "_type") as Number;
            reminder.interval = Storage.getValue(prefix + "_interval") as Number;
            reminder.time = Storage.getValue(prefix + "_time") as String?;
            reminder.enabled = Storage.getValue(prefix + "_enabled") as Boolean;
            reminder.lastTriggered = Storage.getValue(prefix + "_lastTriggered") as Number?;
            _reminders.add(reminder);
        }
    }

    function loadFromJson(jsonString as String) as Void {
        _reminders = [];

        var inner = jsonString.substring(1, jsonString.length() - 1);
        var objects = [];
        var depth = 0;
        var start = 0;
        for (var i = 0; i < inner.length(); i++) {
            var ch = inner.substring(i, i + 1);
            if (ch == "{") {
                if (depth == 0) { start = i; }
                depth++;
            } else if (ch == "}") {
                depth--;
                if (depth == 0) {
                    objects.add(inner.substring(start, i + 1));
                }
            }
        }

        for (var j = 0; j < objects.size(); j++) {
            var obj = objects[j];
            var reminder = new Reminder();
            reminder.id = extractString(obj, "id");
            reminder.text = extractString(obj, "text");
            var rtype = extractString(obj, "type");
            reminder.type = (rtype == "time") ? 1 : 0;
            reminder.interval = extractNumber(obj, "interval");
            reminder.time = extractStringOrNull(obj, "time");
            reminder.enabled = extractBool(obj, "enabled");
            _reminders.add(reminder);
        }

        saveToStorage();
    }

    hidden function extractString(json as String, field as String) as String {
        var key = "\"" + field + "\":\"";
        var idx = json.find(key);
        if (idx == null || idx == -1) { return ""; }
        var s = idx + key.length();
        var rest = json.substring(s, json.length());
        var e = rest.find("\"");
        if (e == null || e == -1) { return ""; }
        return json.substring(s, s + e);
    }

    hidden function extractStringOrNull(json as String, field as String) as String? {
        var key = "\"" + field + "\":\"";
        var idx = json.find(key);
        if (idx == null || idx == -1) { return null; }
        var s = idx + key.length();
        var rest = json.substring(s, json.length());
        var e = rest.find("\"");
        if (e == null || e == -1) { return null; }
        return json.substring(s, s + e);
    }

    hidden function extractNumber(json as String, field as String) as Number {
        var key = "\"" + field + "\":";
        var idx = json.find(key);
        if (idx == null || idx == -1) { return 3600; }
        var s = idx + key.length();
        while (s < json.length() && json.substring(s, s + 1) == " ") { s++; }
        var e = s;
        while (e < json.length()) {
            var ch = json.substring(e, e + 1);
            if (ch == "," || ch == "}" || ch == " ") { break; }
            e++;
        }
        var numStr = json.substring(s, e);
        var result = numStr.toNumber();
        return result != null ? result : 3600;
    }

    hidden function extractBool(json as String, field as String) as Boolean {
        var key = "\"" + field + "\":";
        var idx = json.find(key);
        if (idx == null || idx == -1) { return true; }
        var s = idx + key.length();
        while (s < json.length() && json.substring(s, s + 1) == " ") { s++; }
        if (json.substring(s, s + 4) == "true") { return true; }
        return false;
    }
}
