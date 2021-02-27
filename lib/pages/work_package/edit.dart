import 'package:adhara_markdown/mdeditor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openproject_dart_sdk/api.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

import '../../globals.dart';
import '../../utils.dart';
import '../../widgets.dart';

class EditWorkPackagePage extends StatefulWidget {
  final Project project;
  final WorkPackage workPackage;

  const EditWorkPackagePage({
    Key key,
    this.workPackage,
    @required this.project,
  }) : super(key: key);

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
  Duration _estimatedTime;
  TextEditingController _remainingHoursController = TextEditingController();
  DateTime _from;
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
      if (widget.workPackage.estimatedTime != null) {
        _estimatedTime =
            SerializableDuration.parse(widget.workPackage.estimatedTime);
      }
      // TODO _remainingHoursController.text =
      if (widget.workPackage.startDate != null) {
        _from = widget.workPackage.startDate;
      }
      if (widget.workPackage.dueDate != null) {
        _to = widget.workPackage.dueDate;
      }
      _progressController.text = widget.workPackage.percentageDone?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workPackage == null
              ? "Neues WorkPackage"
              : "${widget.workPackage.subject} bearbeiten",
        ),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
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
              decoration: InputDecoration(labelText: "Status"),
            ),
            CollectionDropDownFormField<WPTypes, WPType>(
              currentItemLink: widget.workPackage?.links?.type,
              project: widget.project,
              onChanged: (WPType type) {
                _wpType = type;
              },
              resolveAllItems: () => TypesApi().apiV3ProjectsProjectIdTypesGet(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, WPType type) {
                return Text(
                  type.name,
                  style: TextStyle(color: HexColor.fromHex(type.color)),
                );
              },
              defaultIndex: 0,
              decoration: InputDecoration(labelText: "Type"),
            ),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: "Subject"),
              maxLength: 255,
            ),
            MarkdownEditor(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              value: widget.workPackage?.description?.raw,
              autoFocus: false,
              tokenConfigs: [],
            ),
            Divider(),
            CollectionDropDownFormField<Users, User>(
              currentItemLink: widget.workPackage?.links?.assignee,
              project: widget.project,
              onChanged: (User user) {
                _assignee = user;
              },
              resolveAllItems: () =>
                  WorkPackagesApi().apiV3ProjectsProjectIdAvailableAssigneesGet(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, User user) {
                return Text(user.name);
              },
              decoration: InputDecoration(labelText: "Assignee"),
            ),
            CollectionDropDownFormField<Users, User>(
              currentItemLink: widget.workPackage?.links?.responsible,
              project: widget.project,
              onChanged: (User user) {
                _accountable = user;
              },
              resolveAllItems: () => WorkPackagesApi()
                  .apiV3ProjectsProjectIdAvailableResponsiblesGet(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, User user) {
                return Text(user.name);
              },
              decoration: InputDecoration(labelText: "Accountable"),
            ),
            Divider(),
            TextFormField(
              initialValue: _estimatedTime?.inHoursDecimal?.toString(),
              decoration: InputDecoration(labelText: "Estimated time"),
              inputFormatters: [
                ThousandsFormatter(allowFraction: true),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _estimatedTime = SerializableDuration.fromHours(
                  double.parse(value),
                );
              },
            ),
            TextFormField(
              controller: _remainingHoursController,
              decoration: InputDecoration(labelText: "Remaining Hours"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            Divider(),
            Text("Date"),
            DateTextFormField(
              initialDate: _from,
              firstDate: DateTime.now().subtract(Duration(days: 36500)),
              lastDate: DateTime.now().add(Duration(days: 36500)),
              onDateChange: (date) => _from = date,
            ),
            Text("-"),
            DateTextFormField(
              initialDate: _to,
              firstDate: DateTime.now().subtract(Duration(days: 36500)),
              lastDate: DateTime.now().add(Duration(days: 36500)),
              onDateChange: (date) => _to = date,
            ),
            TextFormField(
              controller: _progressController,
              decoration: InputDecoration(labelText: "Progress"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
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
            CollectionDropDownFormField<Categories, Category>(
              currentItemLink: widget.workPackage?.links?.category,
              project: widget.project,
              onChanged: (Category category) {
                _category = category;
              },
              resolveAllItems: () => CategoriesApi()
                  .apiV3ProjectsProjectIdCategoriesGet(widget.project.id),
              itemWidget: (BuildContext context, Category category) {
                return Text(category.name);
              },
              decoration: InputDecoration(labelText: "Category"),
            ),
            CollectionDropDownFormField<Versions, Version>(
              currentItemLink: widget.workPackage?.links?.version,
              project: widget.project,
              onChanged: (Version version) {
                _version = version;
              },
              resolveAllItems: () =>
                  VersionsApi().apiV3ProjectsProjectIdVersionsGet(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, Version version) {
                return Text(version.name);
              },
              decoration: InputDecoration(labelText: "Version"),
            ),
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
              decoration: InputDecoration(labelText: "Priority"),
            ),
            MaterialButton(
              child: Text(
                widget.workPackage == null ? "Erstellen" : "Speichern",
              ),
              onPressed: () {
                WorkPackage w = WorkPackage();
                w.links = WorkPackageLinks();

                w.links.status = Link()..href = _status.links.self.href;
                w.links.type = Link()..href = _wpType.links.self.href;

                w.subject = _subjectController.text;
                w.description = Description()
                  ..raw = _descriptionController.text;

                if (_assignee != null)
                  w.links.assignee = Link()..href = _assignee.links.self.href;
                if (_accountable != null)
                  w.links.responsible = Link()
                    ..href = _accountable.links.self.href;

                if (_estimatedTime != null)
                  w.estimatedTime = _estimatedTime.toIso8601String();

                w.startDate = _from;
                w.dueDate = _to;
                w.percentageDone = int.tryParse(_progressController.text);

                if (_category != null)
                  w.links.category = Link()..href = _category.links.self.href;
                if (_version != null)
                  w.links.version = Link()..href = _version.links.self.href;
                if (_priority != null)
                  w.links.priority = Link()..href = _priority.links.self.href;

                if (widget.workPackage != null) {
                  w.lockVersion = widget.workPackage.lockVersion;
                  WorkPackagesApi().apiV3WorkPackagesIdPatch(
                    widget.workPackage.id,
                    workPackage: w,
                  );
                } else {
                  WorkPackagesApi().apiV3ProjectsIdWorkPackagesPost(
                    widget.project.id,
                    w,
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
