import Toybox.Graphics;
import Toybox.Lang;

module FuelTextLayout {

    // Find a layout starting from the largest font. Plus signs force line breaks.
    public function choose(dc as Graphics.Dc, text as String, availableWidth as Number, fonts as Array) as Dictionary {
        var forcedLines = splitAtPlus(text);
        if (forcedLines.size() > 1) {
            for (var forcedFontIndex = 0; forcedFontIndex < fonts.size(); forcedFontIndex++) {
                var forcedFont = fonts[forcedFontIndex];
                var fittedLines = fitForcedLines(dc, forcedLines, forcedFont, availableWidth);
                if (fittedLines != null) {
                    return { :font => forcedFont, :lines => fittedLines };
                }
            }

            return {
                :font => fonts[fonts.size() - 1],
                :lines => forcedLines
            };
        }

        return chooseTwoLines(dc, text, availableWidth, fonts);
    }

    public function chooseTwoLines(
        dc as Graphics.Dc,
        text as String,
        availableWidth as Number,
        fonts as Array
    ) as Dictionary {
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

    public function splitAtPlus(text as String) as Array<String> {
        var lines = [];
        var start = 0;

        while (start <= text.length()) {
            var tail = text.substring(start, text.length());
            var relativeEnd = tail.find("+");
            var end = relativeEnd == null
                ? text.length()
                : start + relativeEnd;
            var line = trimSpaces(text.substring(start, end));

            if (line.length() > 0) {
                lines.add(line);
            }

            if (relativeEnd == null) {
                break;
            }
            start = end + 1;
        }

        return lines.size() > 0 ? lines : [text];
    }

    function fitForcedLines(
        dc as Graphics.Dc,
        forcedLines as Array<String>,
        font,
        availableWidth as Number
    ) as Array<String> or Null {
        var fittedLines = [];

        for (var i = 0; i < forcedLines.size(); i++) {
            var line = forcedLines[i];
            if (dc.getTextWidthInPixels(line, font) <= availableWidth) {
                fittedLines.add(line);
                continue;
            }

            var wrappedLines = splitAtBestSpace(dc, line, font, availableWidth);
            if (wrappedLines == null) {
                return null;
            }
            fittedLines.add(wrappedLines[0]);
            fittedLines.add(wrappedLines[1]);
        }

        return fittedLines;
    }

    function trimSpaces(text as String) as String {
        var start = 0;
        var end = text.length();

        while (start < end && text.substring(start, start + 1).equals(" ")) {
            start++;
        }
        while (end > start && text.substring(end - 1, end).equals(" ")) {
            end--;
        }

        return text.substring(start, end);
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
