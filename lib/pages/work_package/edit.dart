import 'package:adhara_markdown/mdeditor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:openproject_dart_sdk/api.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

import '../../utils.dart';
import '../../widgets.dart';
import '../login.dart';

class EditWorkPackagePage extends StatefulWidget {
  final OpenprojectInstance instance;
  final ProjectModel project;
  final WorkPackageModel workPackage;
  final WorkPackageModel parent;

  const EditWorkPackagePage({
    Key key,
    this.workPackage,
    this.parent,
    required this.project,
    required this.instance,
  }) : super(key: key);

  @override
  _EditWorkPackagePageState createState() => _EditWorkPackagePageState();
}

class _EditWorkPackagePageState extends State<EditWorkPackagePage> {
  StatusModel _status;
  WPType _wpType;
  TextEditingController _subjectController = TextEditingController();
  MarkdownEditorController _descriptionController = MarkdownEditorController();
  Object _assignee;
  AvailableAssigneesModelEmbeddedElementsInner _accountable;
  Duration _estimatedTime;
  TextEditingController _remainingHoursController = TextEditingController();
  DateTime _from;
  DateTime _to;
  TextEditingController _progressController = TextEditingController();
  CategoryModel _category;
  VersionModel _version;
  PriorityModel _priority;

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
            CollectionDropDownFormField<StatusCollectionModel, StatusModel>(
              currentItemLink: widget.workPackage?.links?.status,
              project: widget.project,
              onChanged: (StatusModel status) {
                _status = status;
              },
              resolveAllItems: () => StatusesApi(
                widget.instance.client,
              ).listAllStatuses(),
              itemWidget: (BuildContext context, StatusModel status) {
                return Text(status.name);
              },
              defaultIndex: 0,
              decoration: InputDecoration(labelText: "Status"),
            ),
            CollectionDropDownFormField<TypesByProjectModel, TypesModelEmbeddedElementsInner>(
              currentItemLink: widget.workPackage?.links?.type,
              project: widget.project,
              onChanged: (Object type) {
                _wpType = type;
              },
              resolveAllItems: () => TypesApi(
                widget.instance.client,
              ).listTypesAvailableInAProject(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, Object type) {
                return Text(
                  type.name,
                  style: TextStyle(
                    color: HexColor.fromHex(type.color),
                  ),
                );
              },
              defaultIndex: 0,
              decoration: InputDecoration(
                labelText: "Type",
              ),
            ),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Subject",
              ),
              maxLength: 255,
            ),
            MarkdownEditor(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
              ),
              value: widget.workPackage?.description?.raw,
              autoFocus: false,
              tokenConfigs: [],
            ),
            Divider(),
            CollectionDropDownFormField<AvailableAssigneesModel, AvailableAssigneesModelEmbeddedElementsInner>(
              currentItemLink: widget.workPackage?.links?.assignee,
              project: widget.project,
              onChanged: (Object user) {
                _assignee = user;
              },
              resolveAllItems: () => WorkPackagesApi(
                widget.instance.client,
              ).availableAssignees(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, AvailableAssigneesModelEmbeddedElementsInner user) {
                return Text(user.name);
              },
              decoration: InputDecoration(
                labelText: "Assignee",
              ),
            ),
            CollectionDropDownFormField<AvailableResponsiblesModel, AvailableAssigneesModelEmbeddedElementsInner>(
              currentItemLink: widget.workPackage?.links?.responsible,
              project: widget.project,
              onChanged: (Object user) {
                _accountable = user;
              },
              resolveAllItems: () => WorkPackagesApi(
                widget.instance.client,
              ).availableResponsibles(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, Object user) {
                return Text(user.name);
              },
              decoration: InputDecoration(
                labelText: "Accountable",
              ),
            ),
            Divider(),
            TextFormField(
              initialValue: _estimatedTime?.inHoursDecimal?.toString(),
              decoration: InputDecoration(labelText: "Estimated time"),
              inputFormatters: [
                ThousandsFormatter(
                  allowFraction: true,
                ),
              ],
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  _estimatedTime = null;
                } else {
                  _estimatedTime = SerializableDuration.fromHours(
                    NumberFormat().parse(value),
                  );
                }
              },
            ),
            TextFormField(
              controller: _remainingHoursController,
              decoration: InputDecoration(labelText: "Remaining Hours"),
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            Divider(),
            Text("Date"),
            DateTextFormField(
              initialDate: _from,
              firstDate: DateTime.now().subtract(Duration(
                days: 36500,
              )),
              lastDate: DateTime.now().add(Duration(
                days: 36500,
              )),
              onDateChange: (date) => _from = date,
            ),
            Text("-"),
            DateTextFormField(
              initialDate: _to,
              firstDate: DateTime.now().subtract(Duration(
                days: 36500,
              )),
              lastDate: DateTime.now().add(Duration(
                days: 36500,
              )),
              onDateChange: (date) => _to = date,
            ),
            TextFormField(
              controller: _progressController,
              decoration: InputDecoration(labelText: "Progress"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
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
            CollectionDropDownFormField<CategoriesByProjectModel, CategoryModel>(
              currentItemLink: widget.workPackage?.links?.category,
              project: widget.project,
              onChanged: (CategoryModel category) {
                _category = category;
              },
              resolveAllItems: () => CategoriesApi(
                widget.instance.client,
              ).listCategoriesOfAProject(widget.project.id),
              itemWidget: (BuildContext context, CategoryModel category) {
                return Text(category.name);
              },
              decoration: InputDecoration(labelText: "Category"),
            ),
            CollectionDropDownFormField<VersionsByProjectModel, VersionsModelEmbeddedElementsInner>(
              currentItemLink: widget.workPackage?.links?.version,
              project: widget.project,
              onChanged: (Object version) {
                _version = version;
              },
              resolveAllItems: () => VersionsApi(
                widget.instance.client,
              ).listVersionsAvailableInAProject(
                widget.project.id,
              ),
              itemWidget: (BuildContext context, VersionsModelEmbeddedElementsInner version) {
                return Text(version.name);
              },
              decoration: InputDecoration(labelText: "Version"),
            ),
            CollectionDropDownFormField<PrioritiesModel, PriorityModel>(
              currentItemLink: widget.workPackage?.links?.priority,
              project: widget.project,
              onChanged: (PriorityModel priority) {
                _priority = priority;
              },
              resolveAllItems: () => PrioritiesApi(
                widget.instance.client,
              ).listAllPriorities(),
              itemWidget: (BuildContext context, PriorityModel priority) {
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
                WorkPackageModel w = WorkPackageModel();
                w.links = WorkPackageModelLinks();

                w.links.status = WorkPackageModelLinksStatus(href: _status.links.self.href);
                w.links.type = WorkPackageModelLinksType(href: _wpType.links.self.href);

                w.subject = _subjectController.text;
                w.description = WorkPackageModelDescription(
                  format: WorkPackageModelDescriptionFormatEnum.markdown,
                  raw: _descriptionController.text,
                );

                if (_assignee != null)
                  w.links.assignee = WorkPackageModelLinksAssignee(href: _assignee.links.self.href);
                if (_accountable != null)
                  w.links.responsible = WorkPackageModelLinksResponsible(href: _accountable.links.self.href);

                w.estimatedTime = _estimatedTime?.toIso8601String();

                w.startDate = _from;
                w.dueDate = _to;
                w.percentageDone = int.tryParse(_progressController.text);

                if (_category != null)
                  w.links.category = WorkPackageModelLinksCategory(href: _category.links.self.href);
                if (_version != null)
                  w.links.version = WorkPackageModelLinksVersion(href: _version.links.self.href);
                if (_priority != null)
                  w.links.priority = WorkPackageModelLinksPriority(href: _priority.links.self.href);

                if (widget.workPackage != null) {
                  w.lockVersion = widget.workPackage.lockVersion;
                  WorkPackagesApi(
                    widget.instance.client,
                  ).updateWorkPackage(
                    widget.workPackage.id,
                    workPackageModel: w,
                  );
                } else {
                  WorkPackagesApi(
                    widget.instance.client,
                  ).createProjectWorkPackage(
                    widget.project.id
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
