import 'package:boustro/boustro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

extension ControllerTextExt on DocumentController {
}

/// A paragraph of rich text.
class TextParagraph implements TextParagraphBase<TextParagraph> {
  /// Create a [TextParagraph] from text and attribute spans that are applied to
  /// it.
  TextParagraph([String? text, Iterable<AttributeSpan>? spans])
      : this.attributed(AttributedText(text ?? '', AttributeSpanList(spans)));

  const TextParagraph.attributed(this.attributedText);

  final AttributedText attributedText;

  @override
  ParagraphController createController() {
    return TextParagraphController(attributedText);
  }

  @override
  Widget buildView(BuildContext context) {
    return AttributedTextView(text: attributedText);
  }

  @override
  TextParagraph withSpans(AttributeSpanList spans) =>
      TextParagraph.attributed(attributedText.copyWith(spans: spans));
}

extension BuildTextParagraph on AttributedTextBuilder {
  TextParagraph buildParagraph() {
    return TextParagraph.attributed(build());
  }
}

class TextParagraphController extends ParagraphController
    with TextParagraphControllerMixin {
  TextParagraphController([AttributedText? text])
      : _textController = AttributedTextEditingController(text: text);

  final AttributedTextEditingController _textController;

  @override
  AttributedTextEditingController get textController => _textController;

  @override
  Paragraph? toParagraph() {
    return TextParagraph.attributed(_textController.attributedText);
  }

  @override
  Widget buildEditor(BuildContext context) {
    return TextParagraphEditor(controller: this);
  }
}

/// A widget that displays [AttributedText].
class AttributedTextView extends StatefulWidget {
  /// Creates a widget that displays a [TextParagraph].
  const AttributedTextView({
    Key? key,
    required this.text,
    this.gestureMapper,
    this.selectable = false,
  }) : super(key: key);

  /// Paragraph that is displayed.
  final AttributedText text;

  /// Makes text selectable.
  final bool selectable;

  /// Gesture mapper that manages the lifetimes of the gesture recognizers (if
  /// there are any) created by attributes on [text].
  ///
  /// If null, this widget will create its own [AttributeGestureMapper].
  final AttributeGestureMapper? gestureMapper;

  @override
  _AttributedTextViewState createState() => _AttributedTextViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AttributedText>('text', text));
    properties.add(DiagnosticsProperty<AttributeGestureMapper?>(
        'gestureMapper', gestureMapper));
    properties.add(
        FlagProperty('selectable', value: selectable, ifTrue: 'selectable'));
  }
}

class _AttributedTextViewState extends State<AttributedTextView> {
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
    final spans = widget.text.buildTextSpan(
      context: context,
      gestureMapper: _effectiveGestureMapper,
    );

    final btheme = BoustroTheme.of(context);
    final linePadding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(context).linePadding!)
        .resolve(Directionality.of(context));
    final style = Theme.of(context).textTheme.subtitle1;
    return Padding(
      padding: linePadding,
      child: Padding(
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
      ),
    );
  }
}

class TextParagraphEditor extends StatelessWidget {
  const TextParagraphEditor({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextParagraphController controller;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    final directionality = Directionality.of(context);
    final linePadding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(context).linePadding!)
        .resolve(directionality);

    final key = GlobalObjectKey(controller);

    return TextField(
      key: key,
      controller: controller.textController,
      focusNode: controller.focusNode,
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
  }
}
