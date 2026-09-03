import Toybox.Lang;

class FuelEvent {

    public var isTime as Boolean;
    public var threshold as Float;
    public var text as String;
    public var fired as Boolean;
    public var reachedAtMilliseconds as Number or Null;

    public function initialize(timeEvent as Boolean, value as Float, message as String) {
        isTime = timeEvent;
        threshold = value;
        text = message;
        fired = false;
        reachedAtMilliseconds = null;
    }
}
