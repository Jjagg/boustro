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
  ///
  /// [context] is used to render embeds and modify lines based on their
  /// properties.
  const BoustroView({
    Key? key,
    required this.context,
    required this.document,
  }) : super(key: key);

  /// Context determines how the elements of a [BoustroDocument] are displayed.
  final BoustroContext context;

  /// The contents this view will display.
  final BoustroDocument document;

  @override
  _BoustroViewState createState() => _BoustroViewState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<BoustroContext>('context', context))
      ..add(DiagnosticsProperty<BoustroDocument>('document', document));
  }
}

class _BoustroViewState extends State<BoustroView> {
  late final Map<TextAttribute, GestureRecognizer> _recognizers =
      _createRecognizers();

  Map<TextAttribute, GestureRecognizer> _createRecognizers() {
    final attributes = widget.document.paragraphs.expand<TextAttribute>((p) {
      return p.match<Iterable<TextAttribute>>(
          embed: (e) => [],
          line: (l) => l.spanList.spans.map((s) => s.attribute));
    }).toSet();

    final recognizers = <TextAttribute, GestureRecognizer>{};
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
    return BoustroScope(
      editable: false,
      child: ListView.builder(
        padding: editorPadding,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return _buildParagraph(context, widget.document.paragraphs[index]);
        },
        itemCount: widget.document.paragraphs.length,
      ),
    );
  }

  Widget _buildParagraph(BuildContext buildContext, BoustroParagraph value) {
    Widget result;

    if (value is BoustroLine) {
      final spans = value.spannedText
          .buildTextSpans(style: const TextStyle(), recognizers: _recognizers);
      result = Text.rich(spans);

      result = BoustroLineModifier(
        properties: value.properties,
        handlers: widget.context.lineHandlers,
        child: result,
      );
    } else {
      final embed = value as BoustroParagraphEmbed;
      final builder = widget.context.paragraphEmbedBuilders[embed.type];
      if (builder == null) {
        throw UnsupportedError('Missing builder for embed ${embed.type}.');
      }
      final scope = BoustroScope.of(buildContext);
      result = builder(scope, embed);
    }

    return result;
  }
}

/// Displays the state of a [DocumentController].
class BoustroEditor extends StatelessWidget {
  /// Create an editor with a controller that can have an initial state.
  const BoustroEditor({
    Key? key,
    required this.controller,
    required this.context,
  }) : super(key: key);

  /// Controller that manages the state of the editor.
  final DocumentController controller;

  /// Context determines how the elements of a [BoustroDocument] are displayed.
  final BoustroContext context;

  @override
  Widget build(BuildContext context) {
    return BoustroScope(
      editable: true,
      child: ValueListenableBuilder<BuiltList<ParagraphState>>(
        valueListenable: controller,
        builder: (context, paragraphs, __) =>
            _buildParagraphs(context, paragraphs),
      ),
    );
  }

  Widget _buildParagraphs(
      BuildContext buildContext, BuiltList<ParagraphState> paragraphs) {
    final btheme = BoustroTheme.of(buildContext);
    final directionality = Directionality.of(buildContext);
    final linePadding = btheme.linePadding.resolve(directionality);
    final editorPadding = btheme.editorPadding.resolve(directionality);

    // We want taps in the free area below the listview to set focus
    // on the last editor. To do that we apply editorPadding in a special
    // way.
    // - Horizontal padding is applied around the gesture detector
    // - Top padding is applied to the first line so clicks are handled
    //   by the TextField (also puts the cursor in the right position).
    // - Bottom padding is applied in ListView.padding so it's part of the
    //   scrollable. The cursor will always be put at the end of the line.

    return Padding(
      padding: EdgeInsets.only(
        left: editorPadding.left,
        right: editorPadding.right,
      ),
      child: GestureDetector(
        onTap: () {
          if (controller.paragraphs.isNotEmpty) {
            controller.paragraphs.last.focusNode.requestFocus();
          }
        },
        child: ListView.builder(
          padding: EdgeInsets.only(bottom: editorPadding.bottom),
          shrinkWrap: true,
          addAutomaticKeepAlives: false,
          controller: controller.scrollController,
          itemBuilder: (buildContext, index) {
            Widget result;
            final value = paragraphs[index];
            if (value is LineState) {
              var textFieldPadding = EdgeInsets.only(
                top: linePadding.top,
                bottom: linePadding.bottom,
              );
              if (index == 0) {
                textFieldPadding =
                    textFieldPadding + EdgeInsets.only(top: editorPadding.top);
              }
              final key = GlobalObjectKey(value.controller);
              result = BoustroLineModifier(
                properties: value.properties,
                handlers: context.lineHandlers,
                child: TextField(
                  key: key,
                  controller: value.controller,
                  focusNode: value.focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: textFieldPadding,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              );
            } else {
              final embed = value as EmbedState;
              final builder =
                  context.paragraphEmbedBuilders[embed.content.type];
              if (builder == null) {
                throw UnsupportedError(
                    'Missing builder for embed ${embed.content.type}.');
              }
              final scope = BoustroScope.of(buildContext);
              result = builder(scope, embed.content, embed.focusNode);
            }

            return result;
          },
          itemCount: paragraphs.length,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DocumentController>('controller', controller))
      ..add(DiagnosticsProperty<BoustroContext>('context', context));
  }
}

/// Wraps a [child] and applies [LineParagraphHandler]s based on [properties].
class BoustroLineModifier extends StatelessWidget {
  /// Create a line modifier.
  const BoustroLineModifier({
    Key? key,
    required this.handlers,
    required this.properties,
    required this.child,
  }) : super(key: key);

  /// Nestable builders that modify how the child is wrapped.
  ///
  /// Handlers are applied if [LineParagraphHandler.shouldBeApplied] returns
  /// true when called with [properties].
  final BuiltList<LineParagraphHandler> handlers;

  /// Determines which of [handlers] should be applied.
  final BuiltMap<String, Object> properties;

  /// Child to wrap.
  ///
  /// Within boustro this is a [Text.rich] for [BoustroView] and a
  /// [TextField] for [BoustroEditor].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    final linePadding = btheme.linePadding.resolve(Directionality.of(context));
    return Padding(
      padding:
          EdgeInsets.only(left: linePadding.left, right: linePadding.right),
      child: handlers
          .where((h) => h.shouldBeApplied(properties.asMap()))
          .fold<Widget>(
            child,
            (line, h) => h.modify(context, properties.asMap(), line),
          ),
    );
  }
}
