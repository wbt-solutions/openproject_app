import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals.dart';
import 'login.dart';
import 'start.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    List<String>? accounts = prefs.getStringList("accounts");
    if (accounts != null && accounts.isNotEmpty) {
      storage.read(key: "authenticateLocal").then((String? value) {
        if (value == "true") {
          authentication
              .authenticate(
            localizedReason: "Sie haben Authentication aktiviert",
          )
              .then((bool value) {
            if (value) {
              load(accounts);
            }
          });
        } else {
          load(accounts);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => openLogin(),
      );
    }
  }

  void load(List<String> accounts) {
    loadAccounts(accounts).then((value) {
      if (value.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => StartPage(
              instances: value,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "Verbinden fehlgeschlagen",
              ),
              content: Text(
                "Es konnte keine Verbindung zu einer der gespeicherten OpenProject Instanzen hergestellt werden. Bitte überprüfe, ob eine Internetverbindung vorhanden ist und ob die Instanzen laufen",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openLogin();
                  },
                  child: Text("Neu anmelden"),
                ),
                TextButton(
                  onPressed: () {
                    launch("mailto:development@wbt-solutions.de");
                  },
                  child: Text("Fehler melden"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(),
      ),
    );
  }

  Future<List<OpenprojectInstance>> loadAccounts(List<String> accounts) async {
    List<String> keys =
        await Future.wait(accounts.map((e) => storage.read(key: e)));
    List<OpenprojectInstance> instances = [];
    for (int i = 0; i < accounts.length; i++) {
      Map<String, dynamic> config = jsonDecode(keys[i]);
      instances.add(OpenprojectInstance(
        accessToken: config['accessToken'],
        authenticationType: config['authenticationType'],
        host: accounts[i],
      ));
    }
    List<Map<OpenprojectInstance, bool>> value = await Future.wait(
      instances.map(
        (OpenprojectInstance e) async => {
          e: await e.canConnect(),
        },
      ),
    );
    final testedInstances = value.fold<Map<OpenprojectInstance, bool>>(
      {},
      (previousValue, element) => {
        ...previousValue,
        ...element,
      },
    );
    testedInstances.removeWhere((key, value) => !value);
    return testedInstances.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
