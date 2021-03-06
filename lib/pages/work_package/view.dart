import 'dart:convert';

import 'package:adhara_markdown/adhara_markdown.dart';
import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../utils.dart';
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
                WorkPackagesApi()
                    .apiV3WorkPackagesIdDelete(workPackage.id)
                    .then((value) {
                  Navigator.of(context).pop();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Mir zuweisen"),
              onTap: () {
                Navigator.of(context).pop();
                WorkPackagesApi()
                    .apiV3WorkPackagesIdPatch(
                  workPackage.id,
                  workPackage: WorkPackage()
                    ..lockVersion = workPackage.lockVersion
                    ..links = WorkPackageLinks()
                    ..links.assignee = Link()
                    ..links.assignee.href = me.links.self.href,
                )
                    .catchError((Object error) {
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
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
  TextEditingController _hoursController = TextEditingController();
  List<DropdownMenuItem<TimeEntriesActivity>> _timeEntriesActivitiesDropdown =
      [];
  TimeEntriesActivity _currentTimeEntriesActivity;
  MarkdownEditorController _commentController = MarkdownEditorController();
  DateTime _spentDate;

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
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        child: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text("Zeit buchen"),
              DateTextFormField(
                initialDate: DateTime.now(),
                firstDate: widget.project.createdAt,
                lastDate: widget.project.createdAt.add(Duration(days: 3650)),
                onDateChange: (date) => _spentDate = date,
              ),
              TextFormField(
                controller: _hoursController,
                decoration: InputDecoration(
                  labelText: "Hours",
                ),
                keyboardType: TextInputType.datetime,
              ),
              DropdownButtonFormField(
                items: _timeEntriesActivitiesDropdown,
                value: _currentTimeEntriesActivity,
                onChanged: (item) {},
              ),
              MarkdownEditor(
                controller: _commentController,
                autoFocus: false,
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            TimeEntriesApi()
                .apiV3TimeEntriesPost(
              TimeEntry(
                links: TimeEntryLinks(
                  project: widget.project.links.self,
                  workPackage: widget.workPackage.links.self,
                  activity: _currentTimeEntriesActivity.links.self,
                ),
                hours: SerializableDuration.fromHours(
                  double.parse(
                    _hoursController.text,
                  ),
                ).toIso8601String(),
                comment: Description(raw: _commentController.text),
                spentOn: _spentDate,
              ),
            )
                .then((value) {
              Navigator.of(context).pop();
            }, onError: (e) => apiErrorHandler(e, context));
          },
          child: Text("Create"),
        ),
      ],
    );
  }
}
