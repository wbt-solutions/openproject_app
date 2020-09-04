import 'dart:convert';

import 'package:adhara_markdown/adhara_markdown.dart';
import 'package:flutter/material.dart';
import 'package:openproject_app/utils.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../widgets.dart';
import 'edit.dart';

class ViewWorkPackagePage extends StatelessWidget {
  final User me;
  final Project project;
  final WorkPackage workPackage;

  const ViewWorkPackagePage({
    Key key,
    @required this.workPackage,
    @required this.me,
    @required this.project,
  }) : super(key: key);

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
                WorkPackagesApi()
                    .apiV3WorkPackagesIdDelete(workPackage.id)
                    .then((value) {
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
                  workPackage: WorkPackage()
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
                                  workPackage: WorkPackage()
                                    ..lockVersion = workPackage.lockVersion
                                    ..links = WorkPackageLinks()
                                    ..links.status = Link()
                                    ..links.status.href =
                                        status.links.self.href,
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
            ListTile(
              title: Text("Zeit buchen"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return TimeEntryBookingDialog(
                      project: project,
                      workPackage: workPackage,
                    );
                  },
                );
              },
            )
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

class TimeEntryBookingDialog extends StatefulWidget {
  final Project project;
  final WorkPackage workPackage;

  const TimeEntryBookingDialog({
    Key key,
    @required this.project,
    @required this.workPackage,
  }) : super(key: key);

  @override
  _TimeEntryBookingDialogState createState() => _TimeEntryBookingDialogState();
}

class _TimeEntryBookingDialogState extends State<TimeEntryBookingDialog> {
  TextEditingController _dateController = TextEditingController();
  TextEditingController _hoursController = TextEditingController();
  List<DropdownMenuItem<TimeEntriesActivity>> _timeEntriesActivitiesDropdown =
      [];
  TimeEntriesActivity _currentTimeEntriesActivity;

  @override
  void initState() {
    super.initState();
    defaultApiClient
        .invokeAPI(
      "/api/v3/time_entries/form",
      'POST',
      [],
      TimeEntry(
        spentOn: DateTime.now(),
        links: TimeEntryLinks(
          workPackage: widget.workPackage.links.self,
        ),
      ),
      {},
      {},
      "application/json",
      ["basicAuth"],
    )
        .then((value) {
      List<TimeEntriesActivity> timeEntriesActivities =
          TimeEntriesActivity.listFromJson(jsonDecode(value.body)["_embedded"]
              ["schema"]["activity"]["_embedded"]["allowedValues"]);
      _currentTimeEntriesActivity = timeEntriesActivities[0];
      _timeEntriesActivitiesDropdown = timeEntriesActivities
          .map((e) => DropdownMenuItem(
                child: Text(e.name),
                value: e,
              ))
          .toList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        child: Container(
          width: double.maxFinite,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: "Date",
                ),
              ),
              TextFormField(
                controller: _hoursController,
                decoration: InputDecoration(
                  labelText: "Hours",
                ),
              ),
              DropdownButtonFormField(
                items: _timeEntriesActivitiesDropdown,
                value: _currentTimeEntriesActivity,
                onChanged: (item) {},
              ),
              MarkdownEditor(
                decoration: InputDecoration(
                  labelText: "Comment",
                ),
                tokenConfigs: [],
              )
            ],
          ),
        ),
      ),
      actions: [
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        FlatButton(
          onPressed: () {
            TimeEntriesApi().apiV3TimeEntriesPost(
              TimeEntry(
                links: TimeEntryLinks(
                  project: widget.project.links.self,
                  workPackage: widget.workPackage.links.self,
                  activity: Link(
                    href: "/api/v3/time_entries/activities/3",
                  ),
                ),
                hours: SerializableDuration.fromHours(
                  double.parse(
                    _hoursController.text,
                  ),
                ).toIso8601String(),
                spentOn: DateTime.now(),
              ),
            );
          },
          child: Text("Create"),
        ),
      ],
    );
  }
}
