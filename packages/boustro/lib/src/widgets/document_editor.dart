import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/document.dart';
import 'scope.dart';
import '../core/document_controller.dart';
import 'boustro_theme.dart';

/// An editor for a [Document]. Uses a [DocumentController] to manage its state.
class DocumentEditor extends StatelessWidget {
  /// Create an editor with a controller that can have an initial state.
  const DocumentEditor({
    Key? key,
    required this.controller,
    this.scrollController,
  }) : super(key: key);

  /// Controller that manages the state of the editor.
  final DocumentController controller;

  /// The scroll controller for the [ScrollView] containing the paragraphs.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);

    Widget widget = ValueListenableBuilder<List<ParagraphController>>(
      valueListenable: controller,
      builder: (context, paragraphs, __) {
        return _buildParagraphs(context, paragraphs);
      },
    );

    if (btheme.editorColor != null && btheme.editorColor!.alpha > 0) {
      widget = ColoredBox(
        color: btheme.editorColor!,
        child: widget,
      );
    }

    return BoustroScope(
      controller: controller,
      child: FocusScope(
        node: controller.focusNode,
        child: widget,
      ),
    );
  }

  Widget _buildParagraphs(
    BuildContext context,
    List<ParagraphController> paragraphs,
  ) {
    final btheme = BoustroTheme.of(context);
    final directionality = Directionality.of(context);
    final editorPadding = (btheme.editorPadding ??
            BoustroThemeData.fallbackForContext(context).editorPadding!)
        .resolve(directionality);

    // We want taps in the free area below the listview to set focus
    // on the last editor. To do that we apply editorPadding in a special
    // way.
    // - Horizontal and top padding is applied by SliverPadding
    // - Bottom padding is applied through the SliverFillRemaining below it.

    return CustomScrollView(
      shrinkWrap: true,
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: editorPadding.copyWith(bottom: 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => paragraphs[index].buildEditor(context),
              addAutomaticKeepAlives: false,
              childCount: paragraphs.length,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (controller.paragraphs.isNotEmpty) {
                controller.paragraphs.last.requestFocus();
              }
            },
            child: Container(
              height: editorPadding.bottom,
            ),
          ),
        )
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DocumentController>('controller', controller));
    properties.add(DiagnosticsProperty<ScrollController?>(
        'scrollController', scrollController));
  }
}
