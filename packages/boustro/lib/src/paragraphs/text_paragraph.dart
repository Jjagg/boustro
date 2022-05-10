import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Extensions on [DocumentController] to easily operate text paragraphs.
extension ControllerTextExt on DocumentController {
  /// Toggle the given attribute for the currently focused text controller.
  ///
  /// Does nothing if there is no focused paragraph, or the focused paragraph
  /// does not implement [TextParagraphControllerMixin].
  void toggleAttribute(TextAttribute attribute) {
    final focusedText = getFocusedText();
    focusedText?.textController.toggleAttribute(attribute);
  }
}

/// A paragraph of rich text.
class TextParagraph
    with EquatableMixin
    implements TextParagraphBase<TextParagraph> {
  /// Create a [TextParagraph] from text and attribute spans that are applied to
  /// it.
  TextParagraph([String? text, Iterable<AttributeSpan>? spans])
      : this.attributed(AttributedText(text ?? '', AttributeSpanList(spans)));

  /// Create a text paragraph from an existing [AttributedText].
  const TextParagraph.attributed(this.attributedText);

  /// The attributedText displayed in this paragraph.
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

  @override
  String toString() {
    return attributedText.toString();
  }

  @override
  List<Object?> get props => [attributedText];
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
    final linePadding = (btheme.textPadding ??
            BoustroThemeData.fallbackForContext(context).textPadding!)
        .resolve(Directionality.of(context));
    return Padding(
      padding: linePadding,
      child: widget.selectable
          ? SelectableText.rich(
              spans,
              style: btheme.textStyle,
            )
          : Text.rich(
              spans,
              style: btheme.textStyle,
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
    final linePadding = (btheme.textPadding ??
            BoustroThemeData.fallbackForContext(context).textPadding!)
        .resolve(directionality);

    final key = GlobalObjectKey(controller);

    final documentController = BoustroScope.maybeOf(context)?.controller;
    String? hintText;
    if (documentController == null ||
        (documentController.paragraphs.length < 2 &&
            controller.textController.attributedText.text.string.isEmpty)) {
      hintText = BoustroComponentConfig.of(context).hintText;
    }

    return TextField(
      key: key,
      controller: controller.textController,
      focusNode: controller.focusNode,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: linePadding,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        fillColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      style: btheme.editorTextStyle,
    );
  }
}

/// Property getter extensions for [TextParagraph].
extension TextParagraphGetX on BoustroComponentConfigData {
  /// Hint text displayed for the first paragraph if it is the only paragraph
  /// and it's an empty text paragraph.
  String? get hintText => get<String>('textHintText');
}

/// Property setter extensions for [TextParagraph].
///
/// See the getters in [TextParagraphGetX] for more information on the properties.
extension TextParagraphSetX on BoustroComponentConfigBuilder {
  set hintText(String? value) {
    this['textHintText'] = UnlerpableThemeProperty.maybe<String>(value);
  }
}
