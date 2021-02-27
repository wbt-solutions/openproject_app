import 'package:flutter_test/flutter_test.dart';
import 'package:openproject_app/utils.dart';

void main() {
  test('SerializableDuration toIso8601String Test', () {
    expect(
      Duration(days: 1).toIso8601String(),
      equals("P1D"),
    );
    expect(
      Duration(days: 4, hours: 12, minutes: 30, seconds: 17).toIso8601String(),
      equals("P4DT12H30M17S"),
    );
    expect(
      Duration(days: 7).toIso8601String(),
      equals("P1W"),
    );
    expect(
      Duration(minutes: 13).toIso8601String(),
      equals("PT13M"),
    );
    expect(
      Duration(milliseconds: 100).toIso8601String(),
      equals("PT0.1S"),
    );
    expect(
      Duration(milliseconds: 10).toIso8601String(),
      equals("PT0.01S"),
    );
    expect(
      Duration(microseconds: 1).toIso8601String(),
      equals("PT0.000001S"),
    );
    expect(
      Duration(seconds: 8, microseconds: 1).toIso8601String(),
      equals("PT8.000001S"),
    );
  });

  test('SerializableDuration parse Test', () {
    expect(
      SerializableDuration.parse("P1D"),
      equals(Duration(days: 1)),
    );
    expect(
      SerializableDuration.parse("P4DT12H30M17S"),
      equals(Duration(days: 4, hours: 12, minutes: 30, seconds: 17)),
    );
    expect(
      SerializableDuration.parse("P1W"),
      equals(Duration(days: 7)),
    );
    expect(
      SerializableDuration.parse("PT13M"),
      equals(Duration(minutes: 13)),
    );
    expect(
      SerializableDuration.parse("PT0.1S"),
      equals(Duration(milliseconds: 100)),
    );
    expect(
      SerializableDuration.parse("PT0.01S"),
      equals(Duration(milliseconds: 10)),
    );
    expect(
      SerializableDuration.parse("PT0.000001S"),
      equals(Duration(microseconds: 1)),
    );
    expect(
      SerializableDuration.parse("PT8.000001S"),
      equals(Duration(seconds: 8, microseconds: 1)),
    );
  });
}
