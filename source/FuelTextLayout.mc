import Toybox.Graphics;
import Toybox.Lang;

module FuelTextLayout {

    // Find a one-line or two-line layout starting from the largest font.
    public function choose(dc as Graphics.Dc, text as String, availableWidth as Number, fonts as Array) as Dictionary {
        for (var i = 0; i < fonts.size(); i++) {
            var font = fonts[i];
            if (dc.getTextWidthInPixels(text, font) <= availableWidth) {
                return { :font => font, :lines => [text] };
            }

            var splitLines = splitAtBestSpace(dc, text, font, availableWidth);
            if (splitLines != null) {
                return { :font => font, :lines => splitLines };
            }
        }

        var middle = (text.length() / 2).toNumber();
        return {
            :font => fonts[fonts.size() - 1],
            :lines => [
                text.substring(0, middle),
                text.substring(middle, text.length())
            ]
        };
    }

    function splitAtBestSpace(dc as Graphics.Dc, text as String, font, availableWidth as Number) as Array<String> or Null {
        var best = null;
        var bestDifference = 2147483647;

        for (var i = 1; i < text.length() - 1; i++) {
            if (text.substring(i, i + 1).equals(" ")) {
                var first = text.substring(0, i);
                var second = text.substring(i + 1, text.length());
                var firstWidth = dc.getTextWidthInPixels(first, font);
                var secondWidth = dc.getTextWidthInPixels(second, font);

                if (firstWidth <= availableWidth && secondWidth <= availableWidth) {
                    var difference = (firstWidth - secondWidth).abs();
                    if (difference < bestDifference) {
                        best = [first, second];
                        bestDifference = difference;
                    }
                }
            }
        }

        return best;
    }
}
