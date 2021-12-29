export '../paragraphs/text_paragraph.dart' show TextParagraph;

import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Rich text represented as a list of [Paragraph]s.
@immutable
class Document extends Equatable {
  /// Create a new document with a [List] of initial paragraphs.
  Document([Iterable<Paragraph>? paragraphs])
      : this._paragraphs = paragraphs?.toList() ?? const [];

  final List<Paragraph> _paragraphs;
  late final _immutableParagraphs = List<Paragraph>.unmodifiable(_paragraphs);

  /// The list of paragraphs in this document.
  List<Paragraph> get paragraphs => _immutableParagraphs;

  @override
  List<Object?> get props => [paragraphs];

  @override
  String toString() {
    return paragraphs.toString();
  }
}

/// Base class for paragraphs.
@immutable
abstract class Paragraph {
  /// Constant base constructor for implementations.
  const Paragraph();

  /// Create a widget that displays this embed.
  Widget buildView(BuildContext context);

  /// Create a controller with this paragraph as its initial state.
  ParagraphController createController();
}

/// Interface for controller of a [Paragraph].
///
/// Holds the state of the editable version of the paragraph.
abstract class ParagraphController {
  ParagraphController([
    FocusNode? focusNode,
  ]) {
    this.focusNode = focusNode ?? (_ownedFocusNode = FocusNode());
  }

  late final FocusNode? _ownedFocusNode;
  late final FocusNode focusNode;

  /// Convert the current state of the controller to a [Paragraph].
  Paragraph? toParagraph();

  /// Create the editor for this paragraph.
  Widget buildEditor(BuildContext context);

  bool canConvertFrom(ParagraphController other) => false;

  void convertFrom(ParagraphController other) {
    throw ArgumentError(
        'Unsupported paragraph controller for conversion: $other.');
  }

  void requestFocus() {
    focusNode.requestFocus();
  }

  @mustCallSuper
  void dispose() {
    _ownedFocusNode?.dispose();
  }
}

/// Base class for paragraphs that cannot be edited.
///
/// The widget displayed for paragraphs extending this class will be the same as
/// their view.
///
/// Subclasses only need to override [Paragraph.buildView].
abstract class UneditableParagraph extends ParagraphController
    implements Paragraph {
  @override
  ParagraphController createController() => this;

  @override
  Widget buildEditor(BuildContext context) => buildView(context);

  @override
  Paragraph? toParagraph() => this;
}

mixin TextParagraphControllerMixin implements ParagraphController {
  AttributedTextEditingController get textController;

  @override
  bool canConvertFrom(ParagraphController other) =>
      other is TextParagraphControllerMixin;

  @override
  void convertFrom(ParagraphController other);
}

abstract class TextParagraphBase<T extends TextParagraphBase<T>>
    implements Paragraph {
  AttributedText get attributedText;

  T withSpans(AttributeSpanList spans);
}

/// Builds a [Document]. Can be used fluently.
class DocumentBuilder {
  final List<Paragraph> _paragraphs = [];
  final AttributedTextBuilder _textBuilder = AttributedTextBuilder();

  /// Add a line of rich text to the document.
  void text(void Function(AttributedTextBuilder) build) {
    build(_textBuilder);
    final text = _textBuilder.build();
    final line = TextParagraph.attributed(text);
    _paragraphs.add(line);
  }

  /// Add a paragraph to the document.
  void paragraph(Paragraph paragraph) {
    _paragraphs.add(paragraph);
  }

  /// Finishes building and returns the created document.
  ///
  /// The builder will be reset and can be reused.
  Document build() {
    final doc = Document(_paragraphs);
    _paragraphs.clear();
    return doc;
  }
}
