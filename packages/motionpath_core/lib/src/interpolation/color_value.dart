/// Property keys whose authored values are colours, mirroring the JavaScript
/// `colorKeys` list in the plugin registry.
const Set<String> kMotionPathColorKeys = <String>{
  'color',
  'backgroundColor',
  'borderColor',
};

/// A small set of CSS keywords the demo scenes actually author.
///
/// This is deliberately not the full CSS palette: an unknown keyword returns
/// null so the caller can keep the raw value instead of guessing a colour.
const Map<String, int> _namedColors = <String, int>{
  'transparent': 0x00000000,
  'black': 0xFF000000,
  'white': 0xFFFFFFFF,
  'red': 0xFFFF0000,
  'lime': 0xFF00FF00,
  'green': 0xFF008000,
  'blue': 0xFF0000FF,
  'yellow': 0xFFFFFF00,
  'cyan': 0xFF00FFFF,
  'aqua': 0xFF00FFFF,
  'magenta': 0xFFFF00FF,
  'fuchsia': 0xFFFF00FF,
  'orange': 0xFFFFA500,
  'gray': 0xFF808080,
  'grey': 0xFF808080,
};

int _clampChannel(int value) {
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}

int? _parseHexDigits(String digits) {
  final int? parsed = int.tryParse(digits, radix: 16);
  if (parsed == null) return null;
  switch (digits.length) {
    case 3:
      final int r3 = (parsed >> 8) & 0xF;
      final int g3 = (parsed >> 4) & 0xF;
      final int b3 = parsed & 0xF;
      return 0xFF000000 | (r3 * 17 << 16) | (g3 * 17 << 8) | (b3 * 17);
    case 4:
      final int r4 = (parsed >> 12) & 0xF;
      final int g4 = (parsed >> 8) & 0xF;
      final int b4 = (parsed >> 4) & 0xF;
      final int a4 = parsed & 0xF;
      return (a4 * 17 << 24) | (r4 * 17 << 16) | (g4 * 17 << 8) | (b4 * 17);
    case 6:
      return 0xFF000000 | parsed;
    case 8:
      // CSS authors #rrggbbaa, so the alpha byte moves to the front.
      return ((parsed & 0xFF) << 24) | ((parsed >> 8) & 0xFFFFFF);
    default:
      return null;
  }
}

int? _parseComponent(String raw) {
  if (raw.endsWith('%')) {
    final double? percent = double.tryParse(raw.substring(0, raw.length - 1));
    if (percent == null) return null;
    return _clampChannel((percent * 255 / 100).round());
  }
  final double? value = double.tryParse(raw);
  if (value == null) return null;
  return _clampChannel(value.round());
}

int? _parseAlpha(String raw) {
  if (raw.endsWith('%')) {
    final double? percent = double.tryParse(raw.substring(0, raw.length - 1));
    if (percent == null) return null;
    return _clampChannel((percent * 255 / 100).round());
  }
  final double? value = double.tryParse(raw);
  if (value == null) return null;
  return _clampChannel((value * 255).round());
}

int? _parseRgbFunction(String text) {
  final int open = text.indexOf('(');
  final int close = text.lastIndexOf(')');
  if (open < 0 || close <= open) return null;
  final List<String> parts = text
      .substring(open + 1, close)
      .split(RegExp(r'[\s,/]+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.length < 3) return null;
  final int? red = _parseComponent(parts[0]);
  final int? green = _parseComponent(parts[1]);
  final int? blue = _parseComponent(parts[2]);
  if (red == null || green == null || blue == null) return null;
  var alpha = 255;
  if (parts.length > 3) {
    final int? parsed = _parseAlpha(parts[3]);
    if (parsed == null) return null;
    alpha = parsed;
  }
  return (alpha << 24) | (red << 16) | (green << 8) | blue;
}

/// Parses an authored colour into packed ARGB data.
///
/// Accepts an already packed integer, `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`,
/// `rgb()`, `rgba()`, and a small set of CSS keywords. Returns null when the
/// value is not a colour, so callers can leave it untouched.
int? parseColorArgb(Object? value) {
  if (value is int) return value;
  if (value is! String) return null;
  final String text = value.trim().toLowerCase();
  if (text.isEmpty) return null;
  if (text.startsWith('#')) return _parseHexDigits(text.substring(1));
  if (text.startsWith('rgb')) return _parseRgbFunction(text);
  return _namedColors[text];
}

int _lerpChannel(int from, int to, double t) =>
    _clampChannel((from + (to - from) * t).round());

/// Interpolates two packed ARGB colours channel by channel.
///
/// Lerping the packed integers directly bleeds carries between channels, which
/// is exactly the class of bug this exists to prevent.
int lerpArgb(int from, int to, double t) {
  final double clamped = t.isNaN
      ? 0
      : t < 0
      ? 0
      : t > 1
      ? 1
      : t;
  return (_lerpChannel((from >> 24) & 0xFF, (to >> 24) & 0xFF, clamped) << 24) |
      (_lerpChannel((from >> 16) & 0xFF, (to >> 16) & 0xFF, clamped) << 16) |
      (_lerpChannel((from >> 8) & 0xFF, (to >> 8) & 0xFF, clamped) << 8) |
      _lerpChannel(from & 0xFF, to & 0xFF, clamped);
}

/// Blends two authored colour stop values.
///
/// Falls back to a hard switch at the end of the segment when either side is
/// not a parseable colour, matching the non-numeric behaviour of the reference
/// interpolator.
Object? blendColorValues(Object? from, Object? to, double t) {
  final int? start = parseColorArgb(from);
  final int? end = parseColorArgb(to);
  if (start == null || end == null) return t < 1 ? from : to;
  return lerpArgb(start, end, t);
}
