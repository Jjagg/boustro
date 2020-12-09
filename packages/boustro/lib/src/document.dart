import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

/// Rich text represented as a list of [BoustroParagraph]s.
class BoustroDocument extends ValueNotifier<BuiltList<BoustroParagraph>> {
  /// Create a new boustro document.
  BoustroDocument([List<BoustroParagraph> paragraphs = const []])
      : super(BuiltList.of(paragraphs));

  /// The list of paragraphs in this document.
  BuiltList<BoustroParagraph> get paragraphs => value;

  /// Add the given [paragraph] at [index].
  ///
  /// Will throw [RangeError] if `index < 0` or `index > paragraphs.length`.
  void insert(int index, BoustroParagraph paragraph) {
    value = value.rebuild((b) => b.insert(index, paragraph));
  }

  /// Remove the paragraph at [index].
  ///
  /// Will throw [RangeError] if `index < 0` or `index >= paragraphs.length`.
  void removeAt(int index) {
    value = value.rebuild((b) => b.removeAt(index));
  }
}

/// A paragraph in a [BoustroDocument]. Is either a [BoustroLine] for rich text
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

  T match<T>({
    required T Function(BoustroLine) line,
    required T Function(BoustroParagraphEmbed) embed,
  });

  T deconstruct<T>({
    required T Function(
            String text, SpanList spans, BuiltMap<String, Object> properties)
        line,
    required T Function(String type, Object value) embed,
  });

  int get length => match(
        embed: (_) => 1,
        line: (l) => l.text.length,
      );
}

@immutable
class BoustroLine extends BoustroParagraph {
  BoustroLine(
    this.text,
    this.spanList, {
    BuiltMap<String, Object>? properties,
  })  : properties = properties ?? BuiltMap<String, Object>(),
        super._();

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

@immutable
class BoustroParagraphEmbed extends BoustroParagraph {
  const BoustroParagraphEmbed(this.type, this.value) : super._();

  BoustroParagraphEmbed withValue(Object value) {
    return BoustroParagraphEmbed(type, value);
  }

  final String type;
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
