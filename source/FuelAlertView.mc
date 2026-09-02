import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class FuelAlertView extends WatchUi.DataFieldAlert {

    private const HORIZONTAL_MARGIN = 28;

    private var _owner as FuelAlertField;
    private var _text as String;

    public function initialize(owner as FuelAlertField, text as String) {
        DataFieldAlert.initialize();
        _owner = owner;
        _text = text;
    }

    public function onHide() as Void {
        _owner.onAlertClosed(self);
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var availableWidth = dc.getWidth() - (HORIZONTAL_MARGIN * 2);
        var layout = FuelTextLayout.choose(
            dc,
            _text,
            availableWidth,
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
        var top = (dc.getHeight() - (lineHeight * lines.size())) / 2;

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(
                dc.getWidth() / 2,
                top + (i * lineHeight),
                font,
                lines[i],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }
}
