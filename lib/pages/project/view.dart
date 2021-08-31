import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../widgets.dart';
import '../../widgets/work_package_table.dart';
import '../../widgets/scaffold_back.dart';
import '../login.dart';
import 'edit.dart';

class ViewProjectPage extends StatefulWidget {
  final OpenprojectInstance instance;
  final Project project;

  const ViewProjectPage({
    Key key,
    @required this.project,
    @required this.instance,
  }) : super(key: key);

  @override
  _ViewProjectPageState createState() => _ViewProjectPageState();
}

class _ViewProjectPageState extends State<ViewProjectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ScaffoldBack(),
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
                      instance: widget.instance,
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
                ProjectsApi(
                  widget.instance.client,
                )
                    .apiV3ProjectsIdDelete(
                  widget.project.id,
                )
                    .then((value) {
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
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          DescriptionWidget(
            description: widget.project.description,
          ),
          DescriptionWidget(
            description: widget.project.statusExplanation,
          ),
          WorkPackageTable(
            instance: widget.instance,
            project: widget.project,
          ),
        ],
      ),
    );
  }
}
