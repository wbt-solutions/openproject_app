import 'dart:convert';

import 'package:flutter/material.dart';

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
    List<String> accounts = prefs.getStringList("accounts");
    if (accounts != null && accounts.isNotEmpty) {
      storage.read(key: "authenticateLocal").then((String value) {
        if (value == "true") {
          authentication
              .authenticate(
            localizedReason: "Sie haben Authentication aktiviert",
            sensitiveTransaction: true,
          )
              .then((bool value) {
            if (value) {
              loadAccounts(accounts);
            }
          });
        } else {
          loadAccounts(accounts);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => LoginPage(),
          ),
        ),
      );
    }
  }

  void loadAccounts(List<String> accounts) {
    Future.wait(accounts.map((e) => storage.read(key: e))).then((keys) {
      List<OpenprojectInstance> instances = [];
      for (int i = 0; i < accounts.length; i++) {
        Map<String, dynamic> config = jsonDecode(keys[i]);
        instances.add(OpenprojectInstance(
          accessToken: config['accessToken'],
          authenticationType: config['authenticationType'],
          host: accounts[i],
        ));
      }
      Future.wait(
        instances.map(
          (OpenprojectInstance e) async => {
            e: await e.canConnect(),
          },
        ),
      ).then((List<Map<OpenprojectInstance, bool>> value) {
        final testedInstances = value.fold<Map<OpenprojectInstance, bool>>(
          {},
          (previousValue, element) => {
            ...previousValue,
            ...element,
          },
        );
        testedInstances.removeWhere((key, value) => !value);
        // TODO if no Account remains
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => StartPage(
              instances: testedInstances.keys.toList(),
            ),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
