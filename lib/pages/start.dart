import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../widgets.dart';
import 'project/edit.dart';
import 'project/view.dart';
import 'settings.dart';

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
                    builder: (BuildContext context) => ViewProjectPage(
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
