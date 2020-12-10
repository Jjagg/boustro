import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import 'context.dart';

/// Rich text represented as a list of [BoustroParagraph]s.
@immutable
class BoustroDocument {
  /// Create a new boustro document.
  const BoustroDocument(this.paragraphs);

  /// The list of paragraphs in this document.
  final BuiltList<BoustroParagraph> paragraphs;
}

/// A paragraph in a [BoustroDocument]. Is either a [BoustroLine] for rich text,
/// or a [BoustroParagraphEmbed] for other content.
@immutable
abstract class BoustroParagraph extends Equatable {
  const BoustroParagraph._();

  /// Create a [BoustroLine].
  factory BoustroParagraph.line(
    String text,
    SpanList spans, {
    BuiltMap<String, Object>? properties,
  }) =>
      BoustroLine(text, spans, properties: properties);

  /// Create a [BoustroParagraphEmbed].
  factory BoustroParagraph.embed(
    String type,
    Object value,
  ) =>
      BoustroParagraphEmbed(type, value);

  /// Execute [line] if this is a [BoustroLine] and [embed] if this is a
  /// [BoustroParagraphEmbed].
  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(BoustroParagraphEmbed) embed,
  });

  /// Same as [match], but directly get the members of this paragraph.
  T deconstruct<T>({
    required T Function(
            String text, SpanList spans, BuiltMap<String, Object> properties)
        line,
    required T Function(String type, Object value) embed,
  });
}

/// Immutable representation of a line of rich text in a [BoustroDocument].
@immutable
class BoustroLine extends BoustroParagraph {
  /// Create a boustro line.
  BoustroLine(
    this.text,
    this.spanList, {
    BuiltMap<String, Object>? properties,
  })  : properties = properties ?? BuiltMap<String, Object>(),
        super._();

  /// Create a boustro line with the text and spans of [spannedText].
  BoustroLine.fromSpanned(
    SpannedString spannedText, {
    BuiltMap<String, Object>? properties,
  }) : this(spannedText.text, spannedText.spans, properties: properties);

  /// Plain text in this line.
  final String text;

  /// The formatting for this line.
  final SpanList spanList;

  /// Properties that can affect how this paragraph is displayed.
  final BuiltMap<String, Object> properties;

  /// Get a spanned text that combines [text] and [spanList].
  SpannedString get spannedText => SpannedString(text, spanList);

  @override
  T deconstruct<T>({
    required T Function(String, SpanList, BuiltMap<String, Object>) line,
    required T Function(String, Object) embed,
  }) =>
      line(text, spanList, properties);

  @override
  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(BoustroParagraphEmbed) embed,
  }) =>
      line(this);

  @override
  List<Object?> get props => [text, spanList, properties];

  @override
  String toString() {
    return spannedText.toString();
  }
}

/// Immutable representation of an embed in boustro.
///
/// Embeds are represented with a [type] that's used to find the matching
/// [ParagraphEmbedBuilder] and a [value] which the builder uses to build a
/// widget. The expected runtime type of [value] should be specified by the
/// builder.
@immutable
class BoustroParagraphEmbed extends BoustroParagraph {
  /// Create an embed.
  const BoustroParagraphEmbed(this.type, this.value) : super._();

  /// Create a copy of this embed with [this.value] replaced with [value].
  BoustroParagraphEmbed withValue(Object value) {
    return BoustroParagraphEmbed(type, value);
  }

  /// Type of the embed.
  ///
  /// Matched with [ParagraphEmbedBuilder.type] to find the builder that can
  /// translate [value] into a widget.
  final String type;

  /// Value of the embed.
  ///
  /// Can be any type, but should be of a type expected by the matching builder
  /// for [type].
  final Object value;

  @override
  T deconstruct<T>({
    required T Function(String, SpanList, BuiltMap<String, Object>) line,
    required T Function(String, Object) embed,
  }) =>
      embed(type, value);

  @override
  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(BoustroParagraphEmbed) embed,
  }) =>
      embed(this);

  @override
  List<Object?> get props => [type, value];
}
