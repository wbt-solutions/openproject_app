import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../globals.dart';
import 'start.dart';

class LoginPage extends StatefulWidget {
  final List<OpenprojectInstance> instances;

  LoginPage({
    this.instances = const [],
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _apiKeyController = TextEditingController();
  String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Anmelden"),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  text: "Api Key",
                ),
                Tab(
                  text: "OAuth",
                )
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (message != null)
                            Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).errorColor,
                              ),
                            ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Host",
                            ),
                            controller: _hostController,
                            autocorrect: false,
                            validator: (value) {
                              final uri = Uri.tryParse(value);
                              if (uri == null || !uri.isAbsolute) {
                                return "Bitte gebe einen validen Host ein";
                              }
                              return null;
                            },
                            autofillHints: [
                              AutofillHints.url,
                            ],
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "API Key",
                            ),
                            controller: _apiKeyController,
                            autocorrect: false,
                          ),
                          MaterialButton(
                            child: Text("Anmelden"),
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                final instance = OpenprojectInstance(
                                  accessToken: _apiKeyController.text,
                                  authenticationType: "basicAuth",
                                  host: _hostController.text,
                                );
                                instance.canConnect().then((value) {
                                  List<OpenprojectInstance> instances = [
                                    ...this.widget.instances
                                  ];
                                  if (value) {
                                    instances.add(instance);
                                    prefs.setStringList(
                                      "accounts",
                                      instances
                                          .map((e) => e.client.basePath)
                                          .toList(),
                                    );
                                    storage.write(
                                      key: instance.client.basePath,
                                      value: jsonEncode(
                                        {
                                          "authenticationType": "basicAuth",
                                          "accessToken": _apiKeyController.text,
                                        },
                                      ),
                                    );
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            StartPage(
                                          instances: instances,
                                        ),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      message = "Fehler beim Anmelden!";
                                    });
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text("data"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenprojectInstance {
  ApiClient client;
  User me;
  ProjectTree projectTree;

  OpenprojectInstance({
    String authenticationType,
    String host,
    String accessToken,
  }) {
    client = ApiClient(basePath: host);
    switch (authenticationType) {
      case 'basicAuth':
        client.getAuthentication<HttpBasicAuth>('basicAuth').username =
            'apikey';
        client.getAuthentication<HttpBasicAuth>('basicAuth').password =
            accessToken;
        break;
      case 'oAuth':
        client.getAuthentication<OAuth>('oAuth').accessToken = accessToken;
        break;
    }
    client.addDefaultHeader("Content-Type", "application/json");
    client.addDefaultHeader("Accept-Encoding", "gzip");
  }

  Future<void> refresh() async {
    List<dynamic> userData = await Future.wait([
      UsersApi(client).apiV3UsersIdGet("me"),
      ProjectsApi(client).apiV3ProjectsGet(),
    ]);
    me = userData[0];
    projectTree = ProjectTree(userData[1]);
  }

  Future<bool> canConnect() async {
    try {
      await this.refresh();
      return true;
    } catch (e) {
      print("Exception when calling ActivitiesApi->apiV3ActivitiesIdGet: $e\n");
      return false;
    }
  }

  String get host => Uri.parse(client.basePath).host;
}
