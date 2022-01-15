import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../pages/login.dart';
import '../pages/work_package/edit.dart';
import '../pages/work_package/view.dart';

class WorkPackageTable extends StatefulWidget {
  final OpenprojectInstance instance;
  final Project project;
  final WorkPackage parent;

  WorkPackageTable({
    Key key,
    @required this.instance,
    @required this.project,
    this.parent,
  }) : super(key: key);

  @override
  _WorkPackageTableState createState() => _WorkPackageTableState();
}

class _WorkPackageTableState extends State<WorkPackageTable> {
  List<Map<String, Map<String, dynamic>>> filter = [];
  List<bool> _selections = [
    true,
    false,
  ];

  @override
  void initState() {
    updateFilter();
    super.initState();
  }

  void updateFilter() {
    List<Map<String, Map<String, dynamic>>> filter = [];
    if (_selections[0])
      filter.add({
        "status": Filter(
          operator_: "=",
          values: ["1"],
        ).toJson(),
      });
    if (_selections[1])
      filter.add({
        "assigneeOrGroup": Filter(
          operator_: "=",
          values: ["me"],
        ).toJson(),
      });
    if (widget.parent != null)
      filter.add({
        "parent": Filter(
          operator_: "=",
          values: [widget.parent.id.toString()],
        ).toJson(),
      });
    this.filter = filter;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          ],
        ),
        ToggleButtons(
          children: <Widget>[
            Icon(Icons.real_estate_agent),
            Icon(Icons.person),
          ],
          onPressed: (int index) {
            setState(() {
              _selections[index] = !_selections[index];
              updateFilter();
            });
          },
          isSelected: _selections,
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
                  rows: workPackages.embedded.elements
                      .where(
                        (workPackage) =>
                            workPackage.links.parent.href ==
                            widget.parent?.links?.self?.href,
                      )
                      .map(
                        (workPackage) => DataRow(
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
                        ),
                      )
                      .toList(),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
