import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../widgets.dart';
import '../login.dart';
import '../work_package/edit.dart';
import '../work_package/view.dart';
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
  static const List<Map<String, Map<String, dynamic>>> filterAll = [];
  static List<Map<String, Map<String, dynamic>>> filterMe = [
    {
      "assigneeOrGroup": Filter(operator_: "=", values: ["me"]).toJson()
    },
  ];

  List<Map<String, Map<String, dynamic>>> filter = filterAll;

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
                        instance: widget.instance,
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
            future: WorkPackagesApi(
              widget.instance.client,
            ).apiV3ProjectsIdWorkPackagesGet(
              widget.project.id,
              filters: jsonEncode(filter),
            ),
            builder:
                (BuildContext context, AsyncSnapshot<WorkPackages> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
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
                      for (WorkPackage workPackage
                          in workPackages.embedded.elements)
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
                                builder: (BuildContext context) =>
                                    ViewWorkPackagePage(
                                  project: widget.project,
                                  workPackage: workPackage,
                                  instance: widget.instance,
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
    );
  }
}
