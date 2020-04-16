import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:openproject_app/utils.dart';
import 'package:openproject_dart_sdk/api.dart';

class DescriptionWidget extends StatelessWidget {
  final Description description;
  final int maxLength;

  const DescriptionWidget({
    Key key,
    @required this.description,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text = description.raw;
    if (text == null || text.length == 0)
      return Container(
        width: 0,
        height: 0,
      );
    if (maxLength != null && text.length > maxLength)
      text = text.replaceRange(math.min(maxLength, text.length), text.length, "...");
    switch (description.format) {
      case "markdown":
        return MarkdownBody(data: text);
      default:
        print(text);
        return Text(text);
    }
  }
}

class ProjectsDropDownFormField extends StatefulWidget {
  final Project project;
  final ValueChanged<Project> onChanged;

  const ProjectsDropDownFormField({
    Key key,
    this.project,
    @required this.onChanged,
  }) : super(key: key);

  @override
  _ProjectsDropDownFormFieldState createState() => _ProjectsDropDownFormFieldState();
}

class _ProjectsDropDownFormFieldState extends State<ProjectsDropDownFormField> {
  Future<List<DropdownMenuItem<Project>>> _projectMenuItems;
  Project _currentParent;

  Future<List<DropdownMenuItem<Project>>> fetch() async {
    Projects projects = await ProjectsApi().apiV3ProjectsAvailableParentProjectsGet(
      of_: widget.project != null ? widget.project.identifier : null,
    );
    List<DropdownMenuItem<Project>> projectMenuItems = [];
    for (Project project in projects.embedded.elements) {
      if (widget.project != null &&
          widget.project.links.parent.href != null &&
          project.links.self.href == widget.project.links.parent.href) {
        _currentParent = project;
        widget.onChanged(project);
      }
      projectMenuItems.add(DropdownMenuItem(
        child: Text(project.name),
        value: project, // TODO Removing this selects the right project in the dropdown
      ));
    }
    return projectMenuItems;
  }

  @override
  void initState() {
    super.initState();
    _projectMenuItems = fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DropdownMenuItem<Project>>>(
      future: _projectMenuItems,
      builder: (BuildContext context, AsyncSnapshot<List<DropdownMenuItem<Project>>> snapshot) {
        return DropdownButtonFormField(
          items: snapshot.data,
          value: _currentParent,
          onChanged: (Project project) {
            setState(() {
              _currentParent = project;
            });
            widget.onChanged(project);
          },
        );
      },
    );
  }
}

class TypesDropDownFormField extends StatefulWidget {
  final Project project;
  final Link currentStatus;
  final ValueChanged<WPType> onChanged;

  const TypesDropDownFormField({
    Key key,
    this.currentStatus,
    @required this.project,
    @required this.onChanged,
  }) : super(key: key);

  @override
  _TypesDropDownFormFieldState createState() => _TypesDropDownFormFieldState();
}

class _TypesDropDownFormFieldState extends State<TypesDropDownFormField> {
  Future<List<DropdownMenuItem<WPType>>> _typeMenuItems;
  WPType _currentType;

  Future<List<DropdownMenuItem<WPType>>> fetch() async {
    WPTypes types = await TypesApi().apiV3ProjectsProjectIdTypesGet(widget.project.id);
    List<DropdownMenuItem<WPType>> typeMenuItems = [];
    for (WPType type in types.embedded.elements) {
      if (widget.currentStatus != null &&
          widget.currentStatus.href != null &&
          type.links.self.href == widget.currentStatus.href) {
        _currentType = type;
        widget.onChanged(type);
      }
      typeMenuItems.add(DropdownMenuItem(
        child: Text(
          type.name,
          style: TextStyle(color: HexColor.fromHex(type.color)),
        ),
        value: type,
      ));
    }
    return typeMenuItems;
  }

  @override
  void initState() {
    super.initState();
    _typeMenuItems = fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DropdownMenuItem<WPType>>>(
      future: _typeMenuItems,
      builder: (BuildContext context, AsyncSnapshot<List<DropdownMenuItem<WPType>>> snapshot) {
        return DropdownButtonFormField(
          items: snapshot.data,
          value: _currentType,
          onChanged: (WPType type) {
            setState(() {
              _currentType = type;
            });
            widget.onChanged(type);
          },
        );
      },
    );
  }
}
