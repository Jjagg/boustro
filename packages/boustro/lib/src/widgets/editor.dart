import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import '../document.dart';
import '../scope.dart';
import 'document_controller.dart';
import 'theme.dart';

/// A readonly view of a [Document].
class DocumentView extends StatefulWidget {
  /// Create a document view.
  ///
  /// [document] is the content that will be displayed.
  const DocumentView({
    Key? key,
    required this.document,
    this.physics,
  }) : super(key: key);

  /// The contents this view will display.
  final Document document;

  /// ScrollPhysics to pass to the [ListView] that holds the paragraphs.
  final ScrollPhysics? physics;

  @override
  _DocumentViewState createState() => _DocumentViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Document>('document', document));
    properties.add(DiagnosticsProperty<ScrollPhysics?>('physics', physics,
        defaultValue: null));
  }
}

class _DocumentViewState extends State<DocumentView> {
  late final Map<TextAttribute, GestureRecognizer> _recognizers =
      _createRecognizers();

  Map<TextAttribute, GestureRecognizer> _createRecognizers() {
    final attributes = widget.document.paragraphs.expand<TextAttribute>((p) {
      return p.match<Iterable<TextAttribute>>(
          embed: (e) => [], line: (l) => l.spans.iter.map((s) => s.attribute));
    }).toSet();

    final recognizers = <TextAttribute, GestureRecognizer>{};
    for (final attr in attributes) {
      final value = attr.resolve(context);
      if (value.hasGestures) {
        GestureRecognizer? recognizer;
        if (value.onTap != null) {
          recognizer = TapGestureRecognizer()..onTap = value.onTap;
        } else if (value.onSecondaryTap != null) {
          recognizer = TapGestureRecognizer()
            ..onSecondaryTap = value.onSecondaryTap;
        } else if (value.onDoubleTap != null) {
          recognizer = DoubleTapGestureRecognizer()
            ..onDoubleTap = value.onDoubleTap;
        } else if (value.onLongPress != null) {
          recognizer = LongPressGestureRecognizer()
            ..onLongPress = value.onLongPress;
        }

        if (recognizer != null) {
          recognizers[attr] = recognizer;
        }
      }
    }
    return recognizers;
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);

    return BoustroScope.readonly(
      document: widget.document,
      child: Container(
        color: btheme.editorColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(0),
          physics: widget.physics,
          shrinkWrap: true,
          itemCount: widget.document.paragraphs.length,
          itemBuilder: (context, index) {
            return _buildParagraph(context, widget.document.paragraphs[index]);
          },
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, Paragraph value) {
    return value.match(line: (line) {
      final spans = line.spannedText.buildTextSpans(
        context: context,
        style: Theme.of(context).textTheme.subtitle1!,
        recognizers: _recognizers,
      );

      final btheme = BoustroTheme.of(context);
      final linePadding = (btheme.linePadding ??
              BoustroThemeData.fallbackForContext(context).linePadding!)
          .resolve(Directionality.of(context));
      return Padding(
        padding:
            EdgeInsets.only(left: linePadding.left, right: linePadding.right),
        child: line.modifiers.fold<Widget>(
          Text.rich(spans),
          (line, h) => h.modify(context, line),
        ),
      );
    }, embed: (embed) {
      final btheme = BoustroTheme.of(context);
      final padding = btheme.embedPadding ??
          BoustroThemeData.fallbackForContext(context).embedPadding!;
      return Padding(
        padding: padding,
        child: embed.createView(context),
      );
    });
  }
}

/// An editor for a [Document]. Uses a [DocumentController] to manage its state.
class DocumentEditor extends StatelessWidget {
  /// Create an editor with a controller that can have an initial state.
  const DocumentEditor({
    Key? key,
    required this.controller,
  }) : super(key: key);

  /// Controller that manages the state of the editor.
  final DocumentController controller;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    return BoustroScope.editable(
      controller: controller,
      child: FocusScope(
        node: controller.focusNode,
        child: Container(
          color: btheme.editorColor,
          child: ValueListenableBuilder<BuiltList<ParagraphState>>(
            valueListenable: controller,
            builder: (context, paragraphs, __) {
              return _buildParagraphs(context, paragraphs);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildParagraphs(
    BuildContext context,
    BuiltList<ParagraphState> paragraphs,
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
      controller: controller.scrollController,
      slivers: [
        SliverPadding(
          padding: editorPadding.copyWith(bottom: 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              _buildParagraph,
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
                controller.paragraphs.last.focusNode.requestFocus();
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

  Widget _buildParagraph(BuildContext context, int index) {
    final btheme = BoustroTheme.of(context);
    final directionality = Directionality.of(context);
    final linePadding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(context).linePadding!)
        .resolve(directionality);

    Widget result;
    final value = controller.paragraphs[index];
    if (value is LineState) {
      final key = GlobalObjectKey(value.controller);

      final textField = TextField(
        key: key,
        controller: value.controller,
        focusNode: value.focusNode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.only(
            top: linePadding.top,
            bottom: linePadding.bottom,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      );

      result = Padding(
          padding:
              EdgeInsets.only(left: linePadding.left, right: linePadding.right),
          child: ValueListenableBuilder<BuiltList<LineModifier>>(
            valueListenable: value.modifierController,
            builder: (context, modifiers, child) => modifiers.fold<Widget>(
                child!, (line, h) => h.modify(context, line)),
            child: textField,
          ));
    } else {
      final embed = value as EmbedState;
      result = embed.createEditor(context);
    }

    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DocumentController>('controller', controller));
  }
}
