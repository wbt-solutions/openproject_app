import 'dart:convert';

import 'package:adhara_markdown/adhara_markdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openproject_dart_sdk/api.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../../utils.dart';
import '../../widgets.dart';
import '../../widgets/scaffold_back.dart';
import '../../widgets/work_package_table.dart';
import '../login.dart';
import 'edit.dart';

class ViewWorkPackagePage extends StatelessWidget {
  final OpenprojectInstance instance;
  final Project project;
  final WorkPackage workPackage;

  const ViewWorkPackagePage({
    Key key,
    @required this.workPackage,
    @required this.instance,
    @required this.project,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ScaffoldBack(),
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
                      instance: instance,
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
                WorkPackagesApi(
                  instance.client,
                ).apiV3WorkPackagesIdDelete(workPackage.id).then((value) {
                  Navigator.of(context).pop();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Mir zuweisen"),
              onTap: () {
                Navigator.of(context).pop();
                WorkPackagesApi(
                  instance.client,
                )
                    .apiV3WorkPackagesIdPatch(
                  workPackage.id,
                  workPackage: WorkPackage()
                    ..lockVersion = workPackage.lockVersion
                    ..links = WorkPackageLinks()
                    ..links.assignee = Link()
                    ..links.assignee.href = instance.me.links.self.href,
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
                StatusesApi(
                  instance.client,
                ).apiV3StatusesGet().then((Statuses statuses) {
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
                                WorkPackagesApi(
                                  instance.client,
                                )
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
              leading: Icon(Icons.access_time),
              title: Text("Zeit buchen"),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) {
                    return TimeEntryBookingDialog(
                      instance: instance,
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
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          Timeago(
            builder: (context, value) {
              return Text("Zuletzt aktualisiert $value");
            },
            date: workPackage.updatedAt,
          ),
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
          WorkPackageTable(
            instance: instance,
            project: project,
            parent: workPackage,
          ),
        ],
      ),
    );
  }
}

class TimeEntryBookingDialog extends StatefulWidget {
  final OpenprojectInstance instance;
  final Project project;
  final WorkPackage workPackage;

  const TimeEntryBookingDialog({
    Key key,
    @required this.project,
    @required this.workPackage,
    @required this.instance,
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
    widget.instance.client
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
            TimeEntriesApi(
              widget.instance.client,
            )
                .apiV3TimeEntriesPost(
              TimeEntry(
                links: TimeEntryLinks(
                  project: widget.project.links.self,
                  workPackage: widget.workPackage.links.self,
                  activity: _currentTimeEntriesActivity.links.self,
                ),
                hours: SerializableDuration.fromHours(
                  NumberFormat().parse(
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
