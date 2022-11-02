import 'package:flutter/widgets.dart';

import '../core/document_controller.dart';

/// Lays out an editor and toolbar, and ensures the editor keeps focus when
/// toolbar items are clicked.
class BoustroScaffold extends StatelessWidget {
  const BoustroScaffold({
    Key? key,
    required this.focusNode,
    required this.editor,
    required this.toolbar,
  }) : super(key: key);

  /// Pass [DocumentController.focusNode] so the scaffold can keep focus on
  /// the editor when the toolbar is clicked on web or desktop platforms.
  final FocusNode focusNode;

  /// The text editor, expands to available space.
  final Widget editor;

  /// The toolbar layed out under the editor.
  final Widget toolbar;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      behavior: HitTestBehavior.opaque,
      onTapInside: (_) {},
      // TODO fix tap region
      //focusNode: focusNode,
      child: Column(
        children: [
          Expanded(child: editor),
          toolbar,
        ],
      ),
    );
  }
}
