import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import '../context.dart';
import '../document.dart';
import '../scope.dart';
import 'document_controller.dart';
import 'theme.dart';

/// A readonly view of a [BoustroDocument].
class BoustroView extends StatefulWidget {
  /// Create a boustro view.
  ///
  /// [document] is the content that will be displayed.
  const BoustroView({
    Key? key,
    required this.document,
  }) : super(key: key);

  /// The contents this view will display.
  final BoustroDocument document;

  @override
  _BoustroViewState createState() => _BoustroViewState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoustroDocument>('document', document));
  }
}

class _BoustroViewState extends State<BoustroView> {
  late final Map<TextAttributeValue, GestureRecognizer> _recognizers =
      _createRecognizers();

  Map<TextAttributeValue, GestureRecognizer> _createRecognizers() {
    final attributes =
        widget.document.paragraphs.expand<TextAttributeValue>((p) {
      final attributeTheme = AttributeTheme.of(context);
      return p
          .match<Iterable<TextAttribute>>(
              embed: (e) => [],
              line: (l) => l.spans.iter.map((s) => s.attribute))
          .map((attr) => attr.resolve(attributeTheme));
    }).toSet();

    final recognizers = <TextAttributeValue, GestureRecognizer>{};
    for (final attr in attributes) {
      if (attr.hasGestures) {
        GestureRecognizer? recognizer;
        if (attr.onTap != null) {
          recognizer = TapGestureRecognizer()..onTap = attr.onTap;
        } else if (attr.onSecondaryTap != null) {
          recognizer = TapGestureRecognizer()
            ..onSecondaryTap = attr.onSecondaryTap;
        } else if (attr.onDoubleTap != null) {
          recognizer = DoubleTapGestureRecognizer()
            ..onDoubleTap = attr.onDoubleTap;
        } else if (attr.onLongPress != null) {
          recognizer = LongPressGestureRecognizer()
            ..onLongPress = attr.onLongPress;
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
    final editorPadding = btheme.editorPadding;
    return BoustroScope.readonly(
      document: widget.document,
      child: Container(
        color: btheme.editorColor,
        child: ListView.builder(
          padding: editorPadding,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return _buildParagraph(context, widget.document.paragraphs[index]);
          },
          itemCount: widget.document.paragraphs.length,
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext buildContext, BoustroParagraph value) {
    return value.match(line: (line) {
      final atheme = AttributeTheme.of(context);
      final spans = line.spannedText.buildTextSpans(
        style: const TextStyle(),
        recognizers: _recognizers,
        attributeTheme: atheme,
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
      final scope = BoustroScope.of(buildContext);
      final btheme = BoustroTheme.of(context);
      final padding = btheme.embedPadding ??
          BoustroThemeData.fallbackForContext(buildContext).embedPadding!;
      return Padding(
        padding: padding,
        child: embed.build(scope: scope),
      );
    });
  }
}

/// Displays the state of a [DocumentController].
class BoustroEditor extends StatelessWidget {
  /// Create an editor with a controller that can have an initial state.
  const BoustroEditor({
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
      child: Container(
        color: btheme.editorColor,
        child: ValueListenableBuilder<BuiltList<ParagraphState>>(
          valueListenable: controller,
          builder: (context, paragraphs, __) =>
              _buildParagraphs(context, paragraphs),
        ),
      ),
    );
  }

  Widget _buildParagraphs(
    BuildContext buildContext,
    BuiltList<ParagraphState> paragraphs,
  ) {
    final btheme = BoustroTheme.of(buildContext);
    final directionality = Directionality.of(buildContext);
    final editorPadding = (btheme.editorPadding ??
            BoustroThemeData.fallbackForContext(buildContext).editorPadding!)
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

  Widget _buildParagraph(BuildContext buildContext, int index) {
    final btheme = BoustroTheme.of(buildContext);
    final directionality = Directionality.of(buildContext);
    final linePadding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(buildContext).linePadding!)
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
          child: value.modifiers.fold<Widget>(
            textField,
            (line, h) => h.modify(buildContext, line),
          ));
    } else {
      final embed = value as EmbedState;
      final scope = BoustroScope.of(buildContext);
      result = embed.content.build(scope: scope, focusNode: embed.focusNode);
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
