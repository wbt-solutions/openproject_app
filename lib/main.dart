import 'dart:async';

import 'package:adhara_markdown/adhara_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:openproject_app/project_tree.dart';
import 'package:openproject_app/utils.dart';
import 'package:openproject_app/widgets.dart';
import 'package:openproject_dart_sdk/api.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

final FlutterSecureStorage storage = FlutterSecureStorage();
final LocalAuthentication authentication = LocalAuthentication();
final DateFormat _dateFormat = DateFormat.yMd();

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
          storage.read(key: "authenticateLocal").then((String value) {
            if (value == "true") {
              authentication
                  .authenticateWithBiometrics(
                localizedReason: "Sie haben Authnetication aktiviert",
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
                autocorrect: false,
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
                autocorrect: false,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text(widget.me.name),
            ),
            _buildPanel(widget.me, _projectTree.rootNode),
            ListTile(
              leading: Icon(Icons.add),
              title: Text("Add Project"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => EditProjectPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(User me, ProjectNode node) {
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
                    builder: (BuildContext context) => ProjectPage(
                      project: item.project,
                      me: me,
                    ),
                  ),
                );
              },
            );
          },
          body: _buildPanel(me, item),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}

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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            CheckboxListTile(
              title: Text("Authentifizieren"),
              value: authOnStart,
              onChanged: (bool val) {
                setState(() {
                  authOnStart = val;
                });
                storage.write(key: "authenticateLocal", value: val.toString());
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
      ),
    );
  }
}

class EditProjectPage extends StatefulWidget {
  final Project project;

  const EditProjectPage({Key key, this.project}) : super(key: key);

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  TextEditingController _nameController = TextEditingController();
  Project _parenProject;
  MarkdownEditorController _descriptionController = MarkdownEditorController();
  TextEditingController _identifierController = TextEditingController();
  bool _public = false;
  String _status;
  MarkdownEditorController _statusDescriptionController = MarkdownEditorController();

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project.name;
      _identifierController.text = widget.project.identifier;
      _public = widget.project.public;
      _status = widget.project.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? "Neues Projekt" : "${widget.project.name} bearbeiten"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: ListView(
            children: <Widget>[
              Text("Name"),
              TextFormField(
                controller: _nameController,
              ),
              Text("Subprojekt von"),
              CollectionDropDownFormField<Projects, Project>(
                currentItemLink: widget.project.links.parent,
                onChanged: (Project project) {
                  _parenProject = project;
                },
                project: widget.project,
                itemWidget: (BuildContext context, Project project) {
                  return Text(project.name);
                },
                resolveAllItems: () {
                  return ProjectsApi().apiV3ProjectsAvailableParentProjectsGet(
                    of_: widget.project?.identifier,
                  );
                },
              ),
              Text("Beschreibung"),
              MarkdownEditor(
                autoFocus: false,
                controller: _descriptionController,
                value: widget.project?.description?.raw,
                tokenConfigs: [], // TODO
              ),
              Text("Identifier"),
              TextFormField(
                controller: _identifierController,
              ),
              Text("Public"),
              Checkbox(
                value: _public,
                onChanged: (bool val) {
                  setState(() {
                    _public = val;
                  });
                },
              ),
              Text("Status"),
              DropdownButtonFormField(
                items: [
                  DropdownMenuItem(
                    child: Text("on track"),
                    value: "on track",
                  ),
                  DropdownMenuItem(
                    child: Text("at risk"),
                    value: "at risk",
                  ),
                  DropdownMenuItem(
                    child: Text("off track"),
                    value: "off track",
                  ),
                ],
                value: _status,
                onChanged: (String status) {
                  _status = status;
                },
              ),
              Text("Status Beschreibung"),
              MarkdownEditor(
                autoFocus: false,
                controller: _statusDescriptionController,
                value: widget.project?.statusExplanation?.raw,
                tokenConfigs: [], // TODO
              ),
              MaterialButton(
                child: Text(widget.project == null ? "Erstellen" : "Speichern"),
                onPressed: () {
                  Project sendProject = Project();
                  sendProject.name = _nameController.text;
                  sendProject.links = ProjectLinks();
                  if (_parenProject != null) {
                    sendProject.links.parent = Link();
                    sendProject.links.parent.href = _parenProject.links.self.href;
                  }
                  sendProject.description = Description();
                  sendProject.description.raw = _descriptionController.text;
                  sendProject.identifier = _identifierController.text;
                  sendProject.public = _public;
                  sendProject.status = _status;
                  sendProject.statusExplanation = Description();
                  sendProject.statusExplanation.raw = _statusDescriptionController.text;

                  if (widget.project == null) {
                    ProjectsApi().apiV3ProjectsPost(sendProject);
                  } else {
                    ProjectsApi().apiV3ProjectsIdPatch(widget.project.id, sendProject);
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

class ProjectPage extends StatefulWidget {
  final User me;
  final Project project;

  const ProjectPage({Key key, @required this.project, @required this.me}) : super(key: key);

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  static const String filterAll = "[]";
  static const String filterMe = "[{\"assigneeOrGroup\": {\"operator\":\"=\",\"values\":[\"me\"]}}]";

  String filter = filterAll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Bearbeiten"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => EditProjectPage(
                      project: widget.project,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Löschen"),
              onTap: () {
                ProjectsApi().apiV3ProjectsIdDelete(widget.project.id).then((value) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
            DescriptionWidget(description: widget.project.description),
            DescriptionWidget(description: widget.project.statusExplanation),
            Row(
              children: <Widget>[
                Text(
                  "Arbeitspakete",
                  style: Theme.of(context).textTheme.headline5,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => EditWorkPackagePage(
                          project: widget.project,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person),
                  onPressed: () {
                    setState(() {
                      if (filter == filterAll) {
                        filter = filterMe;
                      } else {
                        filter = filterAll;
                      }
                    });
                  },
                )
              ],
            ),
            FutureBuilder(
              future: WorkPackagesApi().apiV3ProjectsIdWorkPackagesGet(widget.project.id, filters: filter),
              builder: (BuildContext context, AsyncSnapshot<WorkPackages> snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                } else {
                  WorkPackages workPackages = snapshot.data;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      columnSpacing: 10,
                      columns: [
                        DataColumn(
                          label: Text("TYP"),
                        ),
                        DataColumn(
                          label: Text("ID"),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text("THEMA"),
                        ),
                        DataColumn(
                          label: Text("STATUS"),
                        ),
                        DataColumn(
                          label: Text("ZUGEWIESEN AN"),
                        ),
                        DataColumn(
                          label: Text("PRIORITÄT"),
                        ),
                      ],
                      rows: [
                        for (WorkPackage workPackage in workPackages.embedded.elements)
                          DataRow(
                            cells: [
                              DataCell(
                                Text(workPackage.links.type.title),
                              ),
                              DataCell(
                                Text(workPackage.id.toString()),
                              ),
                              DataCell(
                                Text(workPackage.subject),
                              ),
                              DataCell(
                                Text(workPackage.links.status.title),
                              ),
                              DataCell(
                                Text(workPackage.links.assignee.title ?? "-"),
                              ),
                              DataCell(
                                Text(workPackage.links.priority.title),
                              ),
                            ],
                            onSelectChanged: (bool selected) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => WorkPackagePage(
                                    project: widget.project,
                                    workPackage: workPackage,
                                    me: widget.me,
                                  ),
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WorkPackagePage extends StatelessWidget {
  final User me;
  final Project project;
  final WorkPackage workPackage;

  const WorkPackagePage({Key key, @required this.workPackage, @required this.me, @required this.project})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${workPackage.links.type.title} ${workPackage.subject}"),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Bearbeiten"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => EditWorkPackagePage(
                      workPackage: workPackage,
                      project: project,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Löschen"),
              onTap: () {
                WorkPackagesApi().apiV3WorkPackagesIdDelete(workPackage.id).then((value) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Mir zuweisen"),
              onTap: () {
                WorkPackagesApi()
                    .apiV3WorkPackagesIdPatch(
                  workPackage.id,
                  body: WorkPackage()
                    ..lockVersion = workPackage.lockVersion
                    ..links = WorkPackageLinks()
                    ..links.assignee = Link()
                    ..links.assignee.href = me.links.self.href,
                )
                    .then((WorkPackage workPackage) {
                  Navigator.of(context).pop();
                }).catchError((Object error) {
                  if (error is ApiException) {
                    print(error.message);
                  } else {
                    throw error;
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text("Archivieren"),
            ),
            ListTile(
              leading: Icon(Icons.business_center),
              title: Text("Status setzen"),
              onTap: () {
                StatusesApi().apiV3StatusesGet().then((Statuses statuses) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: Text("Wähle den Status:"),
                        children: <Widget>[
                          for (Status status in statuses.embedded.elements)
                            SimpleDialogOption(
                              child: Text(status.name),
                              onPressed: () {
                                WorkPackagesApi()
                                    .apiV3WorkPackagesIdPatch(
                                  workPackage.id,
                                  body: WorkPackage()
                                    ..lockVersion = workPackage.lockVersion
                                    ..links = WorkPackageLinks()
                                    ..links.status = Link()
                                    ..links.status.href = status.links.self.href,
                                )
                                    .then((WorkPackage workPackage) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                }).catchError((Object error) {
                                  if (error is ApiException) {
                                    print(error.message);
                                  } else {
                                    throw error;
                                  }
                                });
                              },
                            ),
                        ],
                      );
                    },
                  );
                });
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Text(
              "Beschreibung",
              style: Theme.of(context).textTheme.headline5,
            ),
            DescriptionWidget(description: workPackage.description),
            Text(
              "Status",
              style: Theme.of(context).textTheme.headline5,
            ),
            Text(workPackage.links.status.title),
          ],
        ),
      ),
    );
  }
}

class EditWorkPackagePage extends StatefulWidget {
  final Project project;
  final WorkPackage workPackage;

  const EditWorkPackagePage({Key key, this.workPackage, @required this.project}) : super(key: key);

  @override
  _EditWorkPackagePageState createState() => _EditWorkPackagePageState();
}

class _EditWorkPackagePageState extends State<EditWorkPackagePage> {
  Status _status;
  WPType _wpType;
  TextEditingController _subjectController = TextEditingController();
  MarkdownEditorController _descriptionController = MarkdownEditorController();
  User _assignee;
  User _accountable;
  TextEditingController _estimatedTimeController = TextEditingController();
  TextEditingController _remainingHoursController = TextEditingController();
  TextEditingController _dateFromController = TextEditingController();
  DateTime _from;
  TextEditingController _dateToController = TextEditingController();
  DateTime _to;
  TextEditingController _progressController = TextEditingController();
  Category _category;
  Version _version;
  Priority _priority;

  @override
  void initState() {
    super.initState();
    if (widget.workPackage != null) {
      _subjectController.text = widget.workPackage.subject;
      _estimatedTimeController.text = widget.workPackage.estimatedTime;
      // TODO _remainingHoursController.text =
      if (widget.workPackage.startDate != null) {
        _dateFromController.text = _dateFormat.format(widget.workPackage.startDate);
        _from = widget.workPackage.startDate;
      }
      if (widget.workPackage.dueDate != null) {
        _dateToController.text = _dateFormat.format(widget.workPackage.dueDate);
        _to = widget.workPackage.dueDate;
      }
      _progressController.text = widget.workPackage.percentageDone?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workPackage == null ? "Neues WorkPackage" : "${widget.workPackage.subject} bearbeiten"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: ListView(
            children: <Widget>[
              Text("Status"),
              CollectionDropDownFormField<Statuses, Status>(
                currentItemLink: widget.workPackage?.links?.status,
                project: widget.project,
                onChanged: (Status status) {
                  _status = status;
                },
                resolveAllItems: () => StatusesApi().apiV3StatusesGet(),
                itemWidget: (BuildContext context, Status status) {
                  return Text(status.name);
                },
                defaultIndex: 0,
              ),
              Text("Type"),
              CollectionDropDownFormField<WPTypes, WPType>(
                currentItemLink: widget.workPackage?.links?.type,
                project: widget.project,
                onChanged: (WPType type) {
                  _wpType = type;
                },
                resolveAllItems: () => TypesApi().apiV3ProjectsProjectIdTypesGet(widget.project.id),
                itemWidget: (BuildContext context, WPType type) {
                  return Text(
                    type.name,
                    style: TextStyle(color: HexColor.fromHex(type.color)),
                  );
                },
                defaultIndex: 0,
              ),
              Text("Subject"),
              TextFormField(
                controller: _subjectController,
                maxLength: 255,
              ),
              Text("Description"),
              MarkdownEditor(
                controller: _descriptionController,
                value: widget.workPackage?.description?.raw,
                autoFocus: false,
                tokenConfigs: [],
              ),
              Divider(),
              Text("Assignee"),
              CollectionDropDownFormField<Users, User>(
                currentItemLink: widget.workPackage?.links?.assignee,
                project: widget.project,
                onChanged: (User user) {
                  _assignee = user;
                },
                resolveAllItems: () =>
                    WorkPackagesApi().apiV3ProjectsProjectIdWorkPackagesAvailableAssigneesGet(widget.project.id),
                itemWidget: (BuildContext context, User user) {
                  return Text(user.name);
                },
              ),
              Text("Accountable"),
              CollectionDropDownFormField<Users, User>(
                currentItemLink: widget.workPackage?.links?.responsible,
                project: widget.project,
                onChanged: (User user) {
                  _accountable = user;
                },
                resolveAllItems: () =>
                    WorkPackagesApi().apiV3ProjectsProjectIdWorkPackagesAvailableResponsiblesGet(widget.project.id),
                itemWidget: (BuildContext context, User user) {
                  return Text(user.name);
                },
              ),
              Divider(),
              Text("Estimated time"),
              TextFormField(
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly,
                ],
                controller: _estimatedTimeController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              Text("Remaining Hours"),
              TextFormField(
                controller: _remainingHoursController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              Divider(),
              Text("Date"),
              TextFormField(
                controller: _dateFromController,
                inputFormatters: [
                  DateInputFormatter(),
                ],
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(Duration(days: 36500)),
                    lastDate: DateTime.now().add(Duration(days: 36500)),
                  ).then((DateTime value) {
                    if (value != null) {
                      _dateFromController.text = _dateFormat.format(value);
                      _from = value;
                    }
                  });
                },
              ),
              Text("-"),
              TextFormField(
                controller: _dateToController,
                inputFormatters: [
                  DateInputFormatter(),
                ],
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(Duration(days: 36500)),
                    lastDate: DateTime.now().add(Duration(days: 36500)),
                  ).then((DateTime value) {
                    if (value != null) {
                      _dateToController.text = _dateFormat.format(value);
                      _to = value;
                    }
                  });
                },
              ),
              Text("Progress"),
              TextFormField(
                controller: _progressController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  WhitelistingTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  int percent = int.tryParse(value);
                  if (percent > 100) {
                    return "Maximal 100%";
                  } else if (percent < 0) {
                    return "Minimum 0%";
                  } else {
                    return null;
                  }
                },
              ),
              Text("Category"),
              CollectionDropDownFormField<Categories, Category>(
                currentItemLink: widget.workPackage?.links?.category,
                project: widget.project,
                onChanged: (Category category) {
                  _category = category;
                },
                resolveAllItems: () => CategoriesApi().apiV3ProjectsProjectIdCategoriesGet(widget.project.id),
                itemWidget: (BuildContext context, Category category) {
                  return Text(category.name);
                },
              ),
              Text("Versions"),
              CollectionDropDownFormField<Versions, Version>(
                currentItemLink: widget.workPackage?.links?.version,
                project: widget.project,
                onChanged: (Version version) {
                  _version = version;
                },
                resolveAllItems: () => VersionsApi().apiV3ProjectsProjectIdVersionsGet(widget.project.id),
                itemWidget: (BuildContext context, Version version) {
                  return Text(version.name);
                },
              ),
              Text("Priority"),
              CollectionDropDownFormField<Priorities, Priority>(
                currentItemLink: widget.workPackage?.links?.priority,
                project: widget.project,
                onChanged: (Priority priority) {
                  _priority = priority;
                },
                resolveAllItems: () => PrioritiesApi().apiV3PrioritiesGet(),
                itemWidget: (BuildContext context, Priority priority) {
                  return Text(priority.name);
                },
                defaultIndex: 1,
              ),
              MaterialButton(
                child: Text(widget.workPackage == null ? "Erstellen" : "Speichern"),
                onPressed: () {
                  WorkPackage w = WorkPackage();
                  w.links = WorkPackageLinks();

                  w.links.status = Link()..href = _status.links.self.href;
                  w.links.type = Link()..href = _wpType.links.self.href;

                  w.subject = _subjectController.text;
                  w.description = Description()..raw = _descriptionController.text;

                  if (_assignee != null) w.links.assignee = Link()..href = _assignee.links.self.href;
                  if (_accountable != null) w.links.responsible = Link()..href = _accountable.links.self.href;

                  if (_estimatedTimeController.text.isNotEmpty)
                    w.estimatedTime = _estimatedTimeController.text; // TODO Formatting?? Remaining hours??

                  w.startDate = _from;
                  w.dueDate = _to;
                  w.percentageDone = int.tryParse(_progressController.text);

                  if (_category != null) w.links.category = Link()..href = _category.links.self.href;
                  if (_version != null) w.links.version = Link()..href = _version.links.self.href;
                  if (_priority != null) w.links.priority = Link()..href = _priority.links.self.href;

                  if (widget.workPackage != null) {
                    w.lockVersion = widget.workPackage.lockVersion;
                    WorkPackagesApi().apiV3WorkPackagesIdPatch(widget.workPackage.id, body: w);
                  } else {
                    WorkPackagesApi().apiV3ProjectsIdWorkPackagesPost(widget.project.id, w);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
