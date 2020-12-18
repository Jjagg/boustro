import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import 'scope.dart';

/// Rich text represented as a list of [Paragraph]s.
@immutable
class Document {
  /// Create a new document.
  const Document(this.paragraphs);

  /// The list of paragraphs in this document.
  final BuiltList<Paragraph> paragraphs;
}

/// A paragraph in a [Document]. Is either a [TextLine] for rich text,
/// or a [ParagraphEmbed] for other content.
@immutable
abstract class Paragraph {
  const Paragraph._();

  /// Execute [line] if this is a [TextLine] and [embed] if this is a
  /// [ParagraphEmbed].
  T match<T>({
    required T Function(TextLine) line,
    required T Function(ParagraphEmbed) embed,
  });
}

/// Immutable representation of a line of rich text in a [Document].
@immutable
class TextLine extends Paragraph with EquatableMixin {
  /// Create a line of rich text.
  TextLine({
    required String text,
    required SpanList spans,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: text.characters,
          spans: spans,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a line with the text and spans of [string].
  TextLine.fromSpanned({
    required SpannedString string,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: string.text,
          spans: string.spans,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a line with directly initialized fields.
  TextLine.built({
    required this.text,
    required this.spans,
    required this.modifiers,
  }) : super._();

  /// Plain text in this line.
  final Characters text;

  /// The formatting for this line.
  final SpanList spans;

  /// Properties that can affect how this paragraph is displayed.
  final BuiltList<LineModifier> modifiers;

  /// Get a spanned text that combines [text] and [spans].
  late final SpannedString spannedText = SpannedString.chars(text, spans);

  @override
  T match<T>({
    required T Function(TextLine) line,
    required T Function(ParagraphEmbed) embed,
  }) =>
      line(this);

  @override
  String toString() {
    return spannedText.toString();
  }

  @override
  List<Object?> get props => [text, spans, modifiers];
}

/// Interface for paragraph embeds.
@immutable
abstract class ParagraphEmbed extends Paragraph {
  /// Constant base constructor for implementations.
  const ParagraphEmbed() : super._();

  @override
  T match<T>({
    required T Function(TextLine) line,
    required T Function(ParagraphEmbed) embed,
  }) =>
      embed(this);

  /// Function that builds the embed widget.
  Widget build({
    required BoustroScope scope,
    FocusNode? focusNode,
  });
}

/// Builds a [Document]. Can be used fluently with cascades.
class DocumentBuilder {
  final List<Paragraph> _paragraphs = [];
  final SpannedStringBuilder _lineBuilder = SpannedStringBuilder();

  /// Add a line of rich text to the document.
  void line(
    void Function(SpannedStringBuilder) build, [
    List<LineModifier>? modifiers = const [],
  ]) {
    build(_lineBuilder);
    final str = _lineBuilder.build();
    final line = TextLine.fromSpanned(string: str, modifiers: modifiers);
    _paragraphs.add(line);
  }

  /// Add an embed to the document.
  void embed(ParagraphEmbed embed) {
    _paragraphs.add(embed);
  }

  /// Finishes building and returns the created document.
  ///
  /// The builder will be reset and can be reused.
  Document build() {
    final doc = Document(_paragraphs.build());
    _paragraphs.clear();
    return doc;
  }
}

/// Wraps a line to modify how it's displayed.
abstract class LineModifier {
  /// Constant base constructor for implementations.
  const LineModifier();

  /// Build a text paragraph with some modification.
  Widget modify(
    BuildContext context,
    Widget child,
  );
}
