import 'package:adhara_markdown/mdeditor.dart';
import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../widgets.dart';
import '../login.dart';

class EditProjectPage extends StatefulWidget {
  final OpenprojectInstance instance;
  final ProjectModel? project;

  const EditProjectPage({
    Key? key,
    this.project,
    this.instance,
  }) : super(key: key);

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  TextEditingController _nameController = TextEditingController();
  ProjectModel _parenProject;
  MarkdownEditorController _descriptionController = MarkdownEditorController();
  TextEditingController _identifierController = TextEditingController();
  bool? _public = false;
  ProjectModelLinksStatus _status;
  MarkdownEditorController _statusDescriptionController =
      MarkdownEditorController();

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project.name;
      _identifierController.text = widget.project.identifier;
      _public = widget.project.public;
      _status = widget.project.links.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project == null
              ? "Neues Projekt"
              : "${widget.project!.name} bearbeiten",
        ),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            CollectionDropDownFormField<Projects, ProjectModel>(
              currentItemLink: widget.project?.links?.parent,
              onChanged: (ProjectModel project) {
                _parenProject = project;
              },
              project: widget.project,
              itemWidget: (BuildContext context, ProjectModel project) {
                return Text(project.name);
              },
              resolveAllItems: () {
                return ProjectsApi(
                  widget.instance.client,
                ).listAvailableParentProjectCandidates(
                  of_: widget.project?.identifier,
                );
              },
              decoration: InputDecoration(
                labelText: "Subprojekt von",
              ),
            ),
            MarkdownEditor(
              decoration: InputDecoration(
                labelText: "Beschreibung",
              ),
              autoFocus: false,
              controller: _descriptionController,
              value: widget.project?.description?.raw,
              tokenConfigs: [], // TODO
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Identifier",
              ),
              controller: _identifierController,
            ),
            Text("Public"),
            Checkbox(
              value: _public,
              onChanged: (bool? val) {
                setState(() {
                  _public = val;
                });
              },
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: "Status",
              ),
              items: [
                for (var status in ProjectStatusEnum.values)
                  DropdownMenuItem(
                    child: Text(status.value),
                    value: status,
                  ),
              ],
              value: _status,
              onChanged: (ProjectModelLinksStatus status) {
                _status = status;
              },
            ),
            MarkdownEditor(
              decoration: InputDecoration(
                labelText: "Status Beschreibung",
              ),
              autoFocus: false,
              controller: _statusDescriptionController,
              value: widget.project?.statusExplanation?.raw,
              tokenConfigs: [], // TODO
            ),
            MaterialButton(
              child: Text(
                widget.project == null ? "Erstellen" : "Speichern",
              ),
              onPressed: () {
                ProjectModel sendProject = ProjectModel();
                sendProject.name = _nameController.text;
                sendProject.links = ProjectModelLinks();
                if (_parenProject != null) {
                  sendProject.links.parent =
                      ProjectModelLinksParent(href: _parenProject.links.self.href);
                }
                sendProject.description = Formattable(
                  format: FormattableFormatEnum.markdown,
                  raw: _descriptionController.text,
                );
                sendProject.identifier = _identifierController.text;
                sendProject.public = _public;
                sendProject.status = _status;
                sendProject.statusExplanation = ProjectModelStatusExplanation(
                  format: ProjectModelStatusExplanationFormatEnum.markdown,
                  raw: _statusDescriptionController.text,
                );

                if (widget.project == null) {
                  ProjectsApi(
                    widget.instance.client,
                  ).createProject(body: sendProject);
                } else {
                  ProjectsApi(
                    widget.instance.client,
                  ).updateProject(
                    widget.project.id,
                    body: sendProject,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
