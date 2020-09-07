import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:openproject_app/globals.dart';
import 'package:openproject_dart_sdk/api.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

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
      text = text.replaceRange(
          math.min(maxLength, text.length), text.length, "...");
    switch (description.format) {
      case DescriptionFormatEnum.markdown_:
        return MarkdownBody(data: text);
      default:
        print(text);
        return Text(text);
    }
  }
}

typedef ItemBuilder<I> = Widget Function(BuildContext context, I child);

class CollectionDropDownFormField<C, I> extends StatefulWidget {
  final Project project;
  final Link currentItemLink;
  final AsyncValueGetter<C> resolveAllItems;
  final ValueChanged<I> onChanged;
  final ItemBuilder<I> itemWidget;
  final int defaultIndex;

  final InputDecoration decoration;

  const CollectionDropDownFormField({
    Key key,
    this.currentItemLink,
    @required this.project,
    @required this.onChanged,
    @required this.resolveAllItems,
    @required this.itemWidget,
    this.defaultIndex,
    this.decoration,
  }) : super(key: key);

  @override
  _CollectionDropDownFormFieldState<C, I> createState() =>
      _CollectionDropDownFormFieldState<C, I>();
}

class _CollectionDropDownFormFieldState<C, I>
    extends State<CollectionDropDownFormField<C, I>> {
  Future<List<DropdownMenuItem<I>>> _menuItems;
  I _currentItem;

  Future<List<DropdownMenuItem<I>>> fetch(BuildContext context) async {
    var items = (await widget.resolveAllItems())
        as dynamic; // We all know it's the collection we get delivered, but to have the compiler silent we say we get something we don't know
    List<DropdownMenuItem<I>> menuItems = [];
    for (var item in items.embedded.elements) {
      if (widget.currentItemLink != null &&
          widget.currentItemLink.href != null &&
          item.links.self.href == widget.currentItemLink.href) {
        _currentItem = item;
      }
      menuItems.add(DropdownMenuItem<I>(
        child: widget.itemWidget(context, item),
        value: item,
      ));
    }
    if (widget.defaultIndex != null)
      _currentItem ??= items.embedded.elements[widget.defaultIndex];
    widget.onChanged(_currentItem);
    return menuItems;
  }

  @override
  void initState() {
    super.initState();
    _menuItems = fetch(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DropdownMenuItem<I>>>(
      future: _menuItems,
      builder: (BuildContext context,
          AsyncSnapshot<List<DropdownMenuItem<I>>> snapshot) {
        return DropdownButtonFormField(
          items: snapshot.data,
          value: _currentItem,
          onChanged: (I item) {
            setState(() {
              _currentItem = item;
            });
            widget.onChanged(item);
          },
          decoration: widget.decoration,
        );
      },
    );
  }
}

class DateTextFormField extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(DateTime date) onDateChange;

  const DateTextFormField({
    Key key,
    this.initialDate,
    @required this.firstDate,
    @required this.lastDate,
    this.onDateChange,
  }) : super(key: key);

  @override
  _DateTextFormFieldState createState() => _DateTextFormFieldState();
}

class _DateTextFormFieldState extends State<DateTextFormField> {
  TextEditingController _dateInputController = TextEditingController();
  DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = widget.initialDate;
  }

  set currentDate(DateTime date) {
    _currentDate = date;
    if (date != null)
      _dateInputController.text = dateFormat.format(date);
    else
      _dateInputController.text = "";
    if (widget.onDateChange != null) widget.onDateChange(date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _dateInputController,
            inputFormatters: [
              DateInputFormatter(),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () {
            showDatePicker(
              context: context,
              initialDate: _currentDate ?? DateTime.now(),
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
            ).then((DateTime value) {
              setState(() {
                currentDate = value;
              });
            });
          },
        ),
      ],
    );
  }
}
