import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../widgets.dart';
import 'login.dart';
import 'project/edit.dart';
import 'project/view.dart';
import 'settings.dart';

class StartPage extends StatefulWidget {
  final List<OpenprojectInstance> instances;

  StartPage({
    Key key,
    @required this.instances,
  }) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  OpenprojectInstance currentInstance;

  @override
  void initState() {
    super.initState();
    currentInstance = widget.instances.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OpenProject von ${currentInstance.me.name}"),
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
            ListTile(
              title: Text(
                currentInstance.me.name,
              ),
            ),
            ListTile(
              title: DropdownButton(
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    currentInstance = value;
                  });
                },
                value: currentInstance,
                items: [
                  for (final inst in widget.instances)
                    DropdownMenuItem(
                      child: Text(inst.client.basePath),
                      value: inst,
                    ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.add),
                tooltip: "Account hinzufügen",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => LoginPage(
                        instances: widget.instances,
                      ),
                    ),
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: currentInstance.refresh,
              child: _buildPanel(
                currentInstance,
                currentInstance.projectTree.rootNode,
              ),
            ),
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

  Widget _buildPanel(
    OpenprojectInstance instance,
    ProjectNode node, {
    int depth = 0,
  }) {
    if (node.children.length == 0) return Text("Keine Subprojekte vorhanden");
    EdgeInsets leftPadding = EdgeInsets.only(left: 9.0 * (depth + 1));
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          node.children[index].isExpanded = !isExpanded;
        });
      },
      children: node.children.map<ExpansionPanel>((ProjectNode item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Padding(
                padding: leftPadding,
                child: Text(item.project.name),
              ),
              subtitle: Padding(
                padding: leftPadding,
                child: DescriptionWidget(
                  description: item.project.description,
                  maxLength: 25,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => ViewProjectPage(
                      project: item.project,
                      instance: instance,
                    ),
                  ),
                );
              },
            );
          },
          body: _buildPanel(
            instance,
            item,
            depth: depth + 1,
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}

class ProjectTree {
  Projects projects;
  ProjectNode rootNode = ProjectNode(null);

  ProjectTree(this.projects) {
    _buildTree(rootNode);
  }

  void _buildTree(ProjectNode node) {
    for (Project project in projects.embedded.elements) {
      if (node.project == null) {
        if (project.links.parent.href == null) {
          _buildNode(node, project);
        }
      } else {
        if (project.links.parent.href == node.project.links.self.href) {
          _buildNode(node, project);
        }
      }
    }
  }

  void _buildNode(ProjectNode rootNode, Project project) {
    ProjectNode projectNode = ProjectNode(project);
    _buildTree(projectNode);
    rootNode.children.add(projectNode);
  }
}

class ProjectNode {
  Project project;
  List<ProjectNode> children = [];
  bool isExpanded = false;

  ProjectNode(this.project);
}
