import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

import 'pages/login.dart';

final SentryClient sentry =
    SentryClient(dsn: 'https://e2f963e6ae3b4f85a21ff9c2f7f54a2d@o406434.ingest.sentry.io/5283998');

void main() {
  FlutterError.onError = (details, {bool forceReport = false}) {
    try {
      sentry.captureException(
        exception: details.exception,
        stackTrace: details.stack,
      );
    } catch (e) {
      print('Sending report to sentry.io failed: $e');
    } finally {
      // Also use Flutter's pretty error logging to the device's console.
      FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
    }
  };

  runZoned(
    () => runApp(OpenProjectApp()),
    onError: (Object error, StackTrace stackTrace) {
      try {
        sentry.captureException(
          exception: error,
          stackTrace: stackTrace,
        );
        print('Error sent to sentry.io: $error');
      } catch (e) {
        print('Sending report to sentry.io failed: $e');
        print('Original error: $error');
      }
    },
  );
}

class OpenProjectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenProject App',
      home: LoginPage(),
    );
  }
}
