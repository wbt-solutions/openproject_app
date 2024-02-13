import 'package:flutter/material.dart';

class ScaffoldBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    final ModalRoute<Object?>? parentRoute = ModalRoute.of(context);
    final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;
    final bool canPop = parentRoute?.canPop ?? false;

    if (hasEndDrawer && canPop) {
      return BackButton();
    } else {
      return SizedBox.shrink();
    }
  }
}
