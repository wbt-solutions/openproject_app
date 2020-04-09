import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:openproject_dart_sdk/api.dart';

class DescriptionWidget extends StatelessWidget {
  final Description description;
  final int maxLength;

  const DescriptionWidget({
    Key key,
    @required this.description,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text = description.raw;
    if (text == null || text.length == 0)
      return Container(
        width: 0,
        height: 0,
      );
    if (maxLength != null && text.length > maxLength)
      text = text.replaceRange(math.min(maxLength, text.length), text.length, "...");
    switch (description.format) {
      case "markdown":
        return MarkdownBody(data: text);
      default:
        print(text);
        return Text(text);
    }
  }
}
