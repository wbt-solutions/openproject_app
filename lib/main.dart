import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openproject_app/model/project_tree.dart';
import 'package:openproject_app/model/widgets.dart';
import 'package:openproject_dart_sdk/api.dart';

final FlutterSecureStorage storage = FlutterSecureStorage();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenProject App',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage();

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    storage.read(key: "host").then((String host) async {
      if (host != null) {
        storage.read(key: "apikey").then((String apiKey) {
          _login(host, apiKey);
        });
      }
    });
  }

  Future<void> _login(String host, String apiKey) async {
    defaultApiClient.basePath = host;
    defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').username = 'apikey';
    defaultApiClient.getAuthentication<HttpBasicAuth>('basicAuth').password = apiKey;

    try {
      User me = await UsersApi().apiV3UsersIdGet("me");
      Projects projects = await ProjectsApi().apiV3ProjectsGet();
      storage.write(key: "host", value: host);
      storage.write(key: "apikey", value: apiKey);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => StartPage(me: me, projects: projects),
        ),
      );
    } catch (e) {
      print("Exception when calling ActivitiesApi->apiV3ActivitiesIdGet: $e\n");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Anmelden"),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Host:"),
              TextFormField(
                controller: _hostController,
                validator: (value) {
                  if (!Uri.parse(value).isAbsolute) {
                    return "Bitte gebe einen validen Host ein";
                  }
                  return null;
                },
              ),
              Text("API Key:"),
              TextFormField(
                controller: _apiKeyController,
              ),
              MaterialButton(
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

class StartPage extends StatefulWidget {
  final User me;
  final Projects projects;

  StartPage({Key key, @required this.me, @required this.projects}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState(this.projects);
}

class _StartPageState extends State<StartPage> {
  ProjectTree _projectTree;

  _StartPageState(Projects projects) {
    _projectTree = ProjectTree(projects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OpenProject von ${widget.me.name}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    widget.me.avatar,
                  ),
                ),
              ),
              child: Text(widget.me.name),
            ),
            _buildPanel(_projectTree.rootNode),
            ListTile(
              leading: Icon(Icons.add),
              title: Text("Add Project"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(ProjectNode node) {
    if (node.children.length == 0) return Text("Keine Subprojekte vorhanden");
    return ExpansionPanelList(
      expandedHeaderPadding: EdgeInsets.only(left: 9),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          node.children[index].isExpanded = !isExpanded;
        });
      },
      children: node.children.map<ExpansionPanel>((ProjectNode item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(item.project.name),
              subtitle: DescriptionWidget(
                description: item.project.description,
                maxLength: 25,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => ProjectPage(project: item.project),
                  ),
                );
              },
            );
          },
          body: _buildPanel(item),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[

          ],
        ),
      ),
    );
  }
}

class ProjectPage extends StatelessWidget {
  final Project project;

  const ProjectPage({Key key, @required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text("Work Packages"),
              onTap: () {
                WorkPackagesApi().apiV3ProjectsIdWorkPackagesGet(project.id).then((WorkPackages wp) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => WorkPackagesPage(
                        project: project,
                        workPackages: wp,
                      ),
                    ),
                  );
                });
              },
            ),
            ListTile(
              title: Text("Calendar"),
            ),
            ListTile(
              title: Text("Members"),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            DescriptionWidget(description: project.description),
            DescriptionWidget(description: project.statusExplanation),
          ],
        ),
      ),
    );
  }
}

class WorkPackagesPage extends StatelessWidget {
  final Project project;
  final WorkPackages workPackages;

  const WorkPackagesPage({Key key, @required this.project, @required this.workPackages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${project.name} Work Packages"),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[],
        ),
      ),
      body: ListView(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 10,
              columns: [
                DataColumn(label: Text("TYP")),
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("THEMA")),
                DataColumn(label: Text("STATUS")),
                DataColumn(label: Text("ZUGEWIESEN AN")),
                DataColumn(label: Text("PRIORITÄT")),
              ],
              rows: [
                for (WorkPackage workPackage in workPackages.embedded.elements)
                  DataRow(
                    cells: [
                      DataCell(Text(workPackage.links.type.title)),
                      DataCell(Text(workPackage.id.toString())),
                      DataCell(Text(workPackage.subject)),
                      DataCell(Text(workPackage.links.status.title)),
                      DataCell(Text(workPackage.links.assignee.title != null ? workPackage.links.assignee.title : "-")),
                      DataCell(Text(workPackage.links.priority.title)),
                    ],
                    onSelectChanged: (bool selected) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => WorkPackagePage(
                            workPackage: workPackage,
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
          MaterialButton(
            child: Row(
              children: <Widget>[
                Icon(Icons.add),
                Text("Create new work package"),
              ],
            ),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}

class WorkPackagePage extends StatelessWidget {
  final WorkPackage workPackage;

  const WorkPackagePage({Key key, this.workPackage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${workPackage.links.type.title} ${workPackage.subject}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Text("DESCRIPTION"),
            DescriptionWidget(description: workPackage.description),
          ],
        ),
      ),
    );
  }
}