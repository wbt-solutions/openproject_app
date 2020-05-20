import 'package:flutter/material.dart';

import 'pages/login.dart';

void main() => runApp(OpenProjectApp());

class OpenProjectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenProject App',
      home: LoginPage(),
    );
  }
}
