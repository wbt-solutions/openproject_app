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
  double get inHoursDecimal => inMicroseconds / Duration.microsecondsPerHour;

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

  static Duration parse(String duration) {
    if (!RegExp(r"^P((\d+W)?(\d+D)?)(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$")
        .hasMatch(duration)) {
      throw ArgumentError("String does not follow correct format");
    }

    final weeks = _parseTime(duration, "W");
    final days = _parseTime(duration, "D");
    final hours = _parseTime(duration, "H");
    final minutes = _parseTime(duration, "M");
    final seconds = _parseTime(duration, "S", hasDecimals: true);

    return Duration(
      days: days + (weeks * 7),
      hours: hours,
      minutes: minutes,
      microseconds: seconds,
    );
  }

  static int _parseTime(String duration, String timeUnit,
      {bool hasDecimals: false}) {
    final decimalTimeMatch = RegExp(r"\d+\.\d+" + timeUnit).firstMatch(duration);

    if (hasDecimals && decimalTimeMatch != null) {
      final timeString = decimalTimeMatch.group(0);
      double decimals =
          double.parse(timeString.substring(0, timeString.length - 1));
      return (decimals * Duration.microsecondsPerSecond).round();
    } else {
      final timeMatch = RegExp(r"\d+" + timeUnit).firstMatch(duration);

      if (timeMatch == null) return 0;
      final timeString = timeMatch.group(0);
      return int.parse(timeString.substring(0, timeString.length - 1)) *
          (hasDecimals ? Duration.microsecondsPerSecond : 1);
    }
  }
}
