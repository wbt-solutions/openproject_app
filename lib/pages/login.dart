import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../globals.dart';
import 'start.dart';

class LoginPage extends StatefulWidget {
  LoginPage();

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _apiKeyController = TextEditingController();
  bool isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    storage.read(key: "host").then((String host) async {
      if (host != null) {
        storage.read(key: "apikey").then((String apiKey) {
          storage.read(key: "authenticateLocal").then((String value) {
            if (value == "true") {
              authentication
                  .authenticateWithBiometrics(
                localizedReason: "Sie haben Authentication aktiviert",
                sensitiveTransaction: true,
              )
                  .then((bool value) {
                if (value) {
                  _login(host, apiKey);
                }
              });
            } else {
              _login(host, apiKey);
            }
          });
        });
      }
    });
  }

  Future<void> _login(String host, String apiKey) async {
    isLoggingIn = true;
    defaultApiClient.basePath = host;
    defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').username =
        'apikey';
    defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').password =
        apiKey;
    defaultApiClient.addDefaultHeader("Accept-Encoding", "gzip");

    try {
      List<dynamic> userData = await Future.wait([
        UsersApi().apiV3UsersIdGet("me"),
        ProjectsApi().apiV3ProjectsGet(),
      ]);
      storage.write(key: "host", value: host);
      storage.write(key: "apikey", value: apiKey);
      isLoggingIn = false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => StartPage(
            me: userData[0],
            projects: userData[1],
          ),
        ),
      );
    } catch (e) {
      isLoggingIn = false;
      print("Exception when calling ActivitiesApi->apiV3ActivitiesIdGet: $e\n");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Anmelden"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: "Host"),
                controller: _hostController,
                autocorrect: false,
                validator: (value) {
                  if (!Uri.parse(value).isAbsolute) {
                    return "Bitte gebe einen validen Host ein";
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "API Key"),
                controller: _apiKeyController,
                autocorrect: false,
              ),
              isLoggingIn
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  : MaterialButton(
                      child: Text("Anmelden"),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _login(_hostController.text, _apiKeyController.text);
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
