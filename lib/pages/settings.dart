import 'package:flutter/material.dart';

import '../globals.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool authOnStart = false;

  @override
  void initState() {
    super.initState();
    storage.read(key: "authenticateLocal").then((String value) {
      setState(() {
        authOnStart = value == "true";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Einstellungen"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          CheckboxListTile(
            title: Text("Authentifizieren"),
            value: authOnStart,
            onChanged: (bool val) {
              setState(() {
                authOnStart = val;
              });
              storage.write(
                key: "authenticateLocal",
                value: val.toString(),
              );
            },
          ),
          ListTile(
            title: Text("Lizenzen"),
            onTap: () => showLicensePage(context: context),
          ),
          ListTile(
            title: Text("Über"),
            onTap: () => showAboutDialog(context: context),
          ),
        ],
      ),
    );
  }
}
