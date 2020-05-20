import 'package:adhara_markdown/mdeditor.dart';
import 'package:flutter/material.dart';
import 'package:openproject_dart_sdk/api.dart';

import '../../widgets.dart';

class EditProjectPage extends StatefulWidget {
  final Project project;

  const EditProjectPage({Key key, this.project}) : super(key: key);

  @override
  _EditProjectPageState createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  TextEditingController _nameController = TextEditingController();
  Project _parenProject;
  MarkdownEditorController _descriptionController = MarkdownEditorController();
  TextEditingController _identifierController = TextEditingController();
  bool _public = false;
  String _status;
  MarkdownEditorController _statusDescriptionController = MarkdownEditorController();

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project.name;
      _identifierController.text = widget.project.identifier;
      _public = widget.project.public;
      _status = widget.project.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? "Neues Projekt" : "${widget.project.name} bearbeiten"),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            CollectionDropDownFormField<Projects, Project>(
              currentItemLink: widget.project?.links?.parent,
              onChanged: (Project project) {
                _parenProject = project;
              },
              project: widget.project,
              itemWidget: (BuildContext context, Project project) {
                return Text(project.name);
              },
              resolveAllItems: () {
                return ProjectsApi().apiV3ProjectsAvailableParentProjectsGet(
                  of_: widget.project?.identifier,
                );
              },
              decoration: InputDecoration(labelText: "Subprojekt von"),
            ),
            MarkdownEditor(
              decoration: InputDecoration(labelText: "Beschreibung"),
              autoFocus: false,
              controller: _descriptionController,
              value: widget.project?.description?.raw,
              tokenConfigs: [], // TODO
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Identifier"),
              controller: _identifierController,
            ),
            Text("Public"),
            Checkbox(
              value: _public,
              onChanged: (bool val) {
                setState(() {
                  _public = val;
                });
              },
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: "Status"),
              items: [
                DropdownMenuItem(
                  child: Text("on track"),
                  value: "on track",
                ),
                DropdownMenuItem(
                  child: Text("at risk"),
                  value: "at risk",
                ),
                DropdownMenuItem(
                  child: Text("off track"),
                  value: "off track",
                ),
              ],
              value: _status,
              onChanged: (String status) {
                _status = status;
              },
            ),
            MarkdownEditor(
              decoration: InputDecoration(labelText: "Status Beschreibung"),
              autoFocus: false,
              controller: _statusDescriptionController,
              value: widget.project?.statusExplanation?.raw,
              tokenConfigs: [], // TODO
            ),
            MaterialButton(
              child: Text(widget.project == null ? "Erstellen" : "Speichern"),
              onPressed: () {
                Project sendProject = Project();
                sendProject.name = _nameController.text;
                sendProject.links = ProjectLinks();
                if (_parenProject != null) {
                  sendProject.links.parent = Link();
                  sendProject.links.parent.href = _parenProject.links.self.href;
                }
                sendProject.description = Description();
                sendProject.description.raw = _descriptionController.text;
                sendProject.identifier = _identifierController.text;
                sendProject.public = _public;
                sendProject.status = _status;
                sendProject.statusExplanation = Description();
                sendProject.statusExplanation.raw = _statusDescriptionController.text;

                if (widget.project == null) {
                  ProjectsApi().apiV3ProjectsPost(sendProject);
                } else {
                  ProjectsApi().apiV3ProjectsIdPatch(widget.project.id, sendProject);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
