import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../document.dart';
import '../scope.dart';
import '../spans/attribute_span.dart';
import 'document_controller.dart';
import 'boustro_theme.dart';

/// A readonly view of a [Document].
class DocumentView extends StatefulWidget {
  /// Create a document view.
  ///
  /// [document] is the content that will be displayed.
  const DocumentView({
    Key? key,
    required this.document,
    this.physics,
    this.primaryScroll,
    this.scrollController,
    this.textSelectable = false,
  }) : super(key: key);

  /// The contents this view will display.
  final Document document;

  /// ScrollPhysics to pass to the [ListView] that holds the paragraphs.
  /// See [ScrollView.physics].
  final ScrollPhysics? physics;

  /// Whether the document view is the primary scroll view.
  /// See [ScrollView.primary].
  final bool? primaryScroll;

  /// The scroll controller for the [ScrollView] containing the paragraphs.
  final ScrollController? scrollController;

  /// Makes text in line paragraphs selectable.
  final bool textSelectable;

  @override
  _DocumentViewState createState() => _DocumentViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Document>('document', document));
    properties.add(DiagnosticsProperty<ScrollPhysics?>('physics', physics,
        defaultValue: null));
    properties.add(FlagProperty('primaryScroll',
        value: primaryScroll, ifTrue: 'primaryScroll'));
    properties.add(DiagnosticsProperty<ScrollController?>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(FlagProperty('textSelectable',
        value: textSelectable, ifTrue: 'selectable'));
  }
}

class _DocumentViewState extends State<DocumentView> {
  final AttributeGestureMapper _gestureMapper = AttributeGestureMapper();

  @override
  void dispose() {
    _gestureMapper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoustroScope.readonly(
      document: widget.document,
      child: ListView.builder(
        addAutomaticKeepAlives: false,
        controller: widget.scrollController,
        physics: widget.physics,
        primary: widget.primaryScroll,
        shrinkWrap: true,
        itemCount: widget.document.paragraphs.length,
        itemBuilder: (context, index) {
          return ParagraphView(
            paragraph: widget.document.paragraphs[index],
            gestureMapper: _gestureMapper,
            textSelectable: widget.textSelectable,
          );
        },
      ),
    );
  }
}

/// Widget that displays a [Paragraph].
class ParagraphView extends StatelessWidget {
  /// Creates a widget that displays a [Paragraph].
  const ParagraphView({
    Key? key,
    required this.paragraph,
    this.gestureMapper,
    this.textSelectable = false,
  }) : super(key: key);

  /// Paragraph that is displayed.
  final Paragraph paragraph;

  /// Makes text in line paragraphs selectable.
  final bool textSelectable;

  /// GestureMapper to pass to [LineParagraphView] if [Paragraph] is a
  /// [LineParagraph].
  final AttributeGestureMapper? gestureMapper;

  @override
  Widget build(BuildContext context) {
    return paragraph.match(
      line: (line) => LineParagraphView(
        line: line,
        gestureMapper: gestureMapper,
        selectable: textSelectable,
      ),
      embed: (embed) => ParagraphEmbedView(
        embed: embed,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Paragraph>('paragraph', paragraph));
    properties.add(DiagnosticsProperty<AttributeGestureMapper?>(
        'gestureMapper', gestureMapper));
    properties.add(FlagProperty('textSelectable',
        value: textSelectable, ifTrue: 'selectable'));
  }
}

/// A widget that displays a line [LineParagraph].
class LineParagraphView extends StatefulWidget {
  /// Creates a widget that displays a [LineParagraph].
  const LineParagraphView({
    Key? key,
    required this.line,
    this.gestureMapper,
    this.selectable = false,
  }) : super(key: key);

  /// Paragraph that is displayed.
  final LineParagraph line;

  /// Makes text selectable.
  final bool selectable;

  /// Gesture mapper that manages the lifetimes of the gesture recognizers (if
  /// there are any) created by attributes on [line].
  ///
  /// If null, this widget will create its own [AttributeGestureMapper].
  final AttributeGestureMapper? gestureMapper;

  @override
  _LineParagraphViewState createState() => _LineParagraphViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LineParagraph>('line', line));
    properties.add(DiagnosticsProperty<AttributeGestureMapper?>(
        'gestureMapper', gestureMapper));
    properties.add(
        FlagProperty('selectable', value: selectable, ifTrue: 'selectable'));
  }
}

class _LineParagraphViewState extends State<LineParagraphView> {
  late final AttributeGestureMapper? _ownedGestureMapper =
      widget.gestureMapper == null ? AttributeGestureMapper() : null;

  AttributeGestureMapper get _effectiveGestureMapper =>
      widget.gestureMapper ?? _ownedGestureMapper!;

  @override
  void dispose() {
    _ownedGestureMapper?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = widget.line.spannedText.buildTextSpan(
      context: context,
      gestureMapper: _effectiveGestureMapper,
    );

    final btheme = BoustroTheme.of(context);
    final linePadding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(context).linePadding!)
        .resolve(Directionality.of(context));
    return Padding(
      padding: EdgeInsets.only(
        left: linePadding.left,
        right: linePadding.right,
      ),
      child: widget.line.modifiers.apply(
        context,
        Builder(
          builder: (context) {
            final style = Theme.of(context).textTheme.subtitle1;
            return Padding(
              padding: EdgeInsets.only(
                top: linePadding.top,
                bottom: linePadding.bottom,
              ),
              child: widget.selectable
                  ? SelectableText.rich(
                      spans,
                      style: style,
                    )
                  : Text.rich(
                      spans,
                      style: style,
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// A widget that displays an embed.
///
/// Turns the embed into a widget using [ParagraphEmbed.createView] and wraps
/// it with padding of [BoustroThemeData.embedPadding] of the [BoustroTheme].
class ParagraphEmbedView extends StatelessWidget {
  /// Creates a widget that displays a [ParagraphEmbed].
  const ParagraphEmbedView({
    Key? key,
    required this.embed,
  }) : super(key: key);

  /// The embed to display.
  final ParagraphEmbed embed;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    final padding = btheme.embedPadding ??
        BoustroThemeData.fallbackForContext(context).embedPadding!;
    return Padding(
      padding: padding,
      child: embed.createView(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ParagraphEmbed>('embed', embed));
  }
}

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

    Widget widget = ValueListenableBuilder<BuiltList<ParagraphState>>(
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

    return BoustroScope.editable(
      controller: controller,
      child: FocusScope(
        node: controller.focusNode,
        child: widget,
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
      controller: scrollController,
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
        ),
      );
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
    properties.add(DiagnosticsProperty<ScrollController?>(
        'scrollController', scrollController));
  }
}
