import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'pages/login.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://e2f963e6ae3b4f85a21ff9c2f7f54a2d@o406434.ingest.sentry.io/5283998';
    },
    appRunner: () => runApp(OpenProjectApp()),
  );
}

class OpenProjectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenProject App',
      home: LoginPage(),
      theme: ThemeData(
        primaryColor: Color.fromRGBO(26, 103, 163, 1),
      ),
    );
  }
}
