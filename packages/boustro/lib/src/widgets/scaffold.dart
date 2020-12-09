import 'package:boustro/src/widgets/document_controller.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Implements the layout structure for a Boustro editor with a toolbar.
class BoustroEditorScaffold extends StatelessWidget {
  BoustroEditorScaffold({
    Key? key,
    this.editor,
    this.toolbar,
  }) : super(key: key);

  /// An editor that will be the main content of the scaffold.
  final Widget? editor;

  /// A toolbar that will be displayed at the bottom of the scaffold.
  /// 
  /// 
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BoustroTheme.of(context).editorColor,
      child: Column(
        children: [
          Expanded(child: editor ?? Container()),
          if (toolbar != null) toolbar!,
        ],
      ),
    );
  }
}
