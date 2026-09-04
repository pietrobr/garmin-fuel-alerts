import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class FuelAlertField extends WatchUi.DataField {

    private const ALERT_DELAY_MILLISECONDS = 10000;
    private const MAIN_CONTENT_VERTICAL_OFFSET = 35;
    private const PREVIOUS_EVENT_DIVIDER_GAP = 2;
    private const PREVIOUS_EVENT_DIVIDER_MARGIN = 55;
    private const PREVIOUS_EVENT_TOP = 20;

    private var _events as Array<FuelEvent>;
    private var _nextIndex as Number;
    private var _distanceMeters as Float or Null;
    private var _timerMilliseconds as Number or Null;
    private var _alertActive as Boolean;
    private var _activeAlert as FuelAlertView or Null;
    private var _lastEventText as String or Null;
    private var _alertsEnabled as Boolean;
    private var _delayAlerts as Boolean;

    public function initialize() {
        DataField.initialize();

        _events = [];
        _nextIndex = 0;
        _distanceMeters = null;
        _timerMilliseconds = null;
        _alertActive = false;
        _activeAlert = null;
        _lastEventText = null;
        _alertsEnabled = true;
        _delayAlerts = true;

        var alertsEnabledProperty = Application.Properties.getValue("alertsEnabled");
        if (alertsEnabledProperty instanceof Boolean) {
            _alertsEnabled = alertsEnabledProperty;
        }

        var delayProperty = Application.Properties.getValue("delayAlerts");
        if (delayProperty instanceof Boolean) {
            _delayAlerts = delayProperty;
        }

        var eventProperty = Application.Properties.getValue("events");
        if (eventProperty instanceof String && eventProperty.length() > 0) {
            parseEvents(eventProperty);
            sortEvents();
        }
    }

    // Garmin calls compute once per second during an activity.
    public function compute(info as Activity.Info) as Void {
        _distanceMeters = info.elapsedDistance;
        _timerMilliseconds = info.timerTime;

        if (!_alertsEnabled || _alertActive) {
            return;
        }

        var dueIndex = findDueEvent();
        if (dueIndex >= 0) {
            showFuelAlert(dueIndex);
        }
    }

    public function onUpdate(dc as Dc) as Void {
        // If the normal field is visible again, the alert overlay is gone.
        if (_alertActive) {
            _activeAlert = null;
            _alertActive = false;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        drawLastEvent(dc);
        updateNextIndex();
        if (_nextIndex >= _events.size()) {
            dc.drawText(
                dc.getWidth() / 2,
                dc.getHeight() / 2,
                Graphics.FONT_MEDIUM,
                "--",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        var event = _events[_nextIndex];
        var layout = FuelTextLayout.choose(
            dc,
            event.text,
            dc.getWidth() - 56,
            [
                Graphics.FONT_LARGE,
                Graphics.FONT_MEDIUM,
                Graphics.FONT_SMALL,
                Graphics.FONT_TINY
            ]
        );
        var font = layout[:font];
        var lines = layout[:lines] as Array<String>;
        var lineHeight = dc.getFontHeight(font);
        var remainingHeight = dc.getFontHeight(Graphics.FONT_SMALL);
        var contentHeight = (lineHeight * lines.size()) + 10 + remainingHeight;
        var top = (dc.getHeight() - contentHeight) / 2;
        if (_lastEventText != null) {
            top += MAIN_CONTENT_VERTICAL_OFFSET;
            var maxTop = dc.getHeight() - contentHeight;
            if (top > maxTop) {
                top = maxTop;
            }
        }

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(
                dc.getWidth() / 2,
                top + (i * lineHeight),
                font,
                lines[i],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        dc.drawText(
            dc.getWidth() / 2,
            top + (lineHeight * lines.size()) + 10,
            Graphics.FONT_SMALL,
            remainingText(event),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // The system closes the overlay; onHide then releases local state.
    public function onAlertClosed(alert as FuelAlertView) as Void {
        if (_activeAlert == alert) {
            _activeAlert = null;
            _alertActive = false;
            WatchUi.requestUpdate();
        }
    }

    private function showFuelAlert(eventIndex as Number) as Void {
        if (_alertActive) {
            return;
        }

        var event = _events[eventIndex];
        var alert = new FuelAlertView(self, event.text);

        // Set state first because showAlert can re-enter the UI lifecycle.
        _alertActive = true;
        _activeAlert = alert;

        try {
            showAlert(alert);
        } catch (ex) {
            // showAlert fails if an alert or settings page is already active.
            _activeAlert = null;
            _alertActive = false;
            return;
        }

        event.fired = true;
        _lastEventText = event.text;
        updateNextIndex();
        notifyRunner();
    }

    private function drawLastEvent(dc as Dc) as Void {
        if (_lastEventText == null) {
            return;
        }

        var text = _lastEventText as String;
        var layout = FuelTextLayout.chooseTwoLines(
            dc,
            text,
            dc.getWidth() - 80,
            [
                Graphics.FONT_SMALL,
                Graphics.FONT_TINY,
                Graphics.FONT_XTINY
            ]
        );
        var font = layout[:font];
        var lines = layout[:lines] as Array<String>;
        var lineHeight = dc.getFontHeight(font);

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(
                dc.getWidth() / 2,
                PREVIOUS_EVENT_TOP + (i * lineHeight),
                font,
                lines[i],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        var dividerY = PREVIOUS_EVENT_TOP
            + (lineHeight * lines.size())
            + PREVIOUS_EVENT_DIVIDER_GAP;
        dc.drawLine(
            PREVIOUS_EVENT_DIVIDER_MARGIN,
            dividerY,
            dc.getWidth() - PREVIOUS_EVENT_DIVIDER_MARGIN,
            dividerY
        );
    }

    private function notifyRunner() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 180),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 180)
            ]);
        }

        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
    }

    private function findDueEvent() as Number {
        for (var i = 0; i < _events.size(); i++) {
            var event = _events[i];
            if (!event.fired && isDue(event)) {
                return i;
            }
        }
        return -1;
    }

    private function isDue(event as FuelEvent) as Boolean {
        var thresholdReached;
        if (event.isTime) {
            thresholdReached = _timerMilliseconds != null
                && (_timerMilliseconds as Number) >= (event.threshold * 60000.0f);
        } else {
            thresholdReached = _distanceMeters != null
                && (_distanceMeters as Float) >= (event.threshold * 1000.0f);
        }

        if (!thresholdReached || !_delayAlerts) {
            return thresholdReached;
        }

        var now = System.getTimer();
        if (event.reachedAtMilliseconds == null) {
            event.reachedAtMilliseconds = now;
            return false;
        }

        return now - (event.reachedAtMilliseconds as Number)
            >= ALERT_DELAY_MILLISECONDS;
    }

    private function updateNextIndex() as Void {
        while (_nextIndex < _events.size() && _events[_nextIndex].fired) {
            _nextIndex++;
        }
    }

    private function remainingText(event as FuelEvent) as String {
        if (event.isTime) {
            if (_timerMilliseconds == null) {
                return "in -- min";
            }

            var elapsedMinutes = (_timerMilliseconds as Number) / 60000.0f;
            var remainingMinutes = event.threshold - elapsedMinutes;
            if (remainingMinutes < 0.0f) {
                remainingMinutes = 0.0f;
            }

            if (remainingMinutes < 2.0f) {
                var seconds = Math.ceil(remainingMinutes * 60.0f).toNumber();
                return "in " + seconds.format("%d") + " sec";
            }

            var minutes = Math.ceil(remainingMinutes).toNumber();
            return "in " + minutes.format("%d") + " min";
        }

        if (_distanceMeters == null) {
            return "in -- km";
        }

        var elapsedKm = (_distanceMeters as Float) / 1000.0f;
        var remainingKm = event.threshold - elapsedKm;
        if (remainingKm < 0.0f) {
            remainingKm = 0.0f;
        }
        return "in " + remainingKm.format("%.1f") + " km";
    }

    private function parseEvents(value as String) as Void {
        var start = 0;

        while (start < value.length()) {
            var tail = value.substring(start, value.length());
            var relativeEnd = tail.find(";");
            var end = relativeEnd == null
                ? value.length()
                : start + relativeEnd;

            if (end > start) {
                parseEvent(value.substring(start, end));
            }
            start = end + 1;
        }
    }

    private function parseEvent(entry as String) as Void {
        var separator = entry.find(":");
        if (separator == null || separator <= 0 || separator >= entry.length() - 1) {
            return;
        }

        var prefix = entry.substring(0, separator);
        var message = entry.substring(separator + 1, entry.length());
        var isTime = prefix.substring(0, 1).equals("T")
            || prefix.substring(0, 1).equals("t");
        var numericPart = isTime
            ? prefix.substring(1, prefix.length())
            : prefix;

        if (numericPart.length() == 0 || message.length() == 0) {
            return;
        }

        try {
            var threshold = numericPart.toFloat();
            if (threshold >= 0.0f) {
                _events.add(new FuelEvent(isTime, threshold, message));
            }
        } catch (ex) {
            // One malformed entry must not invalidate the remaining entries.
        }
    }

    // Sort thresholds ascending; distance wins ties.
    private function sortEvents() as Void {
        for (var i = 1; i < _events.size(); i++) {
            var current = _events[i];
            var j = i - 1;

            while (j >= 0 && comesAfter(_events[j], current)) {
                _events[j + 1] = _events[j];
                j--;
            }
            _events[j + 1] = current;
        }
    }

    private function comesAfter(left as FuelEvent, right as FuelEvent) as Boolean {
        if (left.threshold != right.threshold) {
            return left.threshold > right.threshold;
        }
        return left.isTime && !right.isTime;
    }
}
