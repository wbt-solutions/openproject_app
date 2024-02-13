import 'dart:convert';

class FilterManager {
  List<String> _filterNames = [];
  Map<String, Filter> _filter = {};
  Map<String, bool> _active = {};

  void addInactive(String filterName, Filter filter) {
    _filterNames.add(filterName);
    _filter[filterName] = filter;
    _active[filterName] = false;
  }

  void addActive(String filterName, Filter filter) {
    _filterNames.add(filterName);
    _filter[filterName] = filter;
    _active[filterName] = true;
  }

  void toggleAtIndex(int index) {
    _active[_filterNames.elementAt(index)] = !(_active[_filterNames.elementAt(index)] == true);
  }

  void setActiveAtIndex(int index, bool active) {
    _active[_filterNames.elementAt(index)] = active;
  }

  List<bool> states() {
    return _filterNames.map((e) => _active[e]!).toList();
  }

  void setActive(String filterName, bool active) {
    _active[filterName] = active;
  }

  bool? isActive(String filterName) {
    return _active[filterName];
  }

  String toJsonString() {
    return jsonEncode(
        _filter.entries.where((element) => _active[element.key]!).map((e) => {
          e.key: e.value.toJson()
        }).toList());
  }
}

class Filter {
  Filter({required this.operator, this.values = const [],});

  final String operator;

  final List<String> values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Filter && other.operator == operator &&
          other.values == values;

  @override
  int get hashCode => operator.hashCode + values.hashCode;

  @override
  String toString() => 'Filter[operator_=$operator, values=$values]';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'operator': operator, 'values': values,};
  }
}
