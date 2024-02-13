
import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../api_filter.dart';
import '../pages/login.dart';
import '../pages/work_package/edit.dart';
import '../pages/work_package/view.dart';

class WorkPackageTable extends StatefulWidget {
  final OpenprojectInstance instance;
  final ProjectModel project;
  final WorkPackageModel? parent;

  WorkPackageTable({
    Key? key,
    required this.instance,
    required this.project,
    this.parent,
  }) : super(key: key);

  @override
  _WorkPackageTableState createState() => _WorkPackageTableState();
}

class _WorkPackageTableState extends State<WorkPackageTable> {
  FilterManager filterManager = FilterManager();

  @override
  void initState() {
    filterManager.addActive(
      "status",
      Filter(
        operator: "=",
        values: ["1"],
      ),
    );
    filterManager.addInactive(
      "assigneeOrGroup",
      Filter(
        operator: "=",
        values: ["me"],
      ),
    );
    if (widget.parent != null)
      filterManager.addActive(
        "parent",
        Filter(
          operator: "=",
          values: [widget.parent!.id.toString()],
        ),
      );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            Text(
              "Arbeitspakete",
              style: Theme.of(context).textTheme.headlineSmall,
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
              filterManager.toggleAtIndex(index);
            });
          },
          isSelected: filterManager.states(),
        ),
        FutureBuilder(
          future: WorkPackagesApi(
            widget.instance.client,
          ).getProjectWorkPackageCollection(
            widget.project.id!,
            filters: filterManager.toJsonString(),
          ),
          builder: (BuildContext context,
              AsyncSnapshot<WorkPackagesModel> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              WorkPackagesModel workPackages = snapshot.data;
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
