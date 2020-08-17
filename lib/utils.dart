import 'dart:ui';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension SerializableDuration on Duration {

  String toIso8601String() {
    String string = "P";

    int inDays = this.inDays;

    int d = inDays % 7;

    int inWeeks = inDays ~/ 7;

    if (inWeeks > 0) string += "${inWeeks}W";

    if (d > 0) string += "${d}D";

    bool timeAdded = false;

    int h = this.inHours % Duration.hoursPerDay;
    if (h > 0) {
      if (!timeAdded) {
        string += "T";
        timeAdded = true;
      }
      string += "${h}H";
    }

    int m = this.inMinutes % Duration.minutesPerHour;
    if (m > 0) {
      if (!timeAdded) {
        string += "T";
        timeAdded = true;
      }
      string += "${m}M";
    }

    int s = this.inSeconds % Duration.secondsPerMinute;
    int fraction = this.inMicroseconds % Duration.microsecondsPerSecond;
    if (fraction > 0) {
      double i = s + fraction / Duration.microsecondsPerSecond;
      if (!timeAdded) {
        string += "T";
        timeAdded = true;
      }
      string += "${i}S";
    } else {
      if (s > 0) {
        if (!timeAdded) {
          string += "T";
          timeAdded = true;
        }
        string += "${s}S";
      }
    }

    return string;
  }
}
