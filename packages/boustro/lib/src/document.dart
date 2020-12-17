import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import 'context.dart';
import 'scope.dart';

/// Rich text represented as a list of [BoustroParagraph]s.
@immutable
class BoustroDocument {
  /// Create a new boustro document.
  const BoustroDocument(this.paragraphs);

  /// The list of paragraphs in this document.
  final BuiltList<BoustroParagraph> paragraphs;
}

/// A paragraph in a [BoustroDocument]. Is either a [BoustroLine] for rich text,
/// or a [ParagraphEmbed] for other content.
@immutable
abstract class BoustroParagraph {
  const BoustroParagraph._();

  /// Execute [line] if this is a [BoustroLine] and [embed] if this is a
  /// [ParagraphEmbed].
  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(ParagraphEmbed) embed,
  });
}

/// Immutable representation of a line of rich text in a [BoustroDocument].
@immutable
class BoustroLine extends BoustroParagraph with EquatableMixin {
  /// Create a boustro line.
  BoustroLine({
    required String text,
    required SpanList spans,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: text.characters,
          spans: spans,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a boustro line with the text and spans of [string].
  BoustroLine.fromSpanned({
    required SpannedString string,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: string.text,
          spans: string.spans,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a boustro line with directly initialized fields.
  BoustroLine.built({
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
  late final SpannedString spannedText = SpannedString(text, spans);

  @override
  T match<T>({
    required T Function(BoustroLine) line,
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
abstract class ParagraphEmbed extends BoustroParagraph {
  /// Constant base constructor for implementations.
  const ParagraphEmbed() : super._();

  @override
  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(ParagraphEmbed) embed,
  }) =>
      embed(this);

  /// Function that builds the embed widget.
  Widget build({
    required BoustroScope scope,
    FocusNode? focusNode,
  });
}

/// Builds a [BoustroDocument]. Can be used fluently with cascades.
class DocumentBuilder {
  final List<BoustroParagraph> _paragraphs = [];
  final SpannedStringBuilder _lineBuilder = SpannedStringBuilder();

  /// Add a line of rich text to the document.
  void line(
    void Function(SpannedStringBuilder) build, [
    List<LineModifier>? modifiers = const [],
  ]) {
    build(_lineBuilder);
    final str = _lineBuilder.build();
    final line = BoustroLine.fromSpanned(string: str, modifiers: modifiers);
    _paragraphs.add(line);
  }

  /// Add an embed to the document.
  void embed(ParagraphEmbed embed) {
    _paragraphs.add(embed);
  }

  /// Finishes building and returns the created document.
  ///
  /// The builder will be reset and can be reused.
  BoustroDocument build() {
    final doc = BoustroDocument(_paragraphs.build());
    _paragraphs.clear();
    return doc;
  }
}
