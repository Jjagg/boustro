import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

/// Rich text represented as a list of [Paragraph]s.
@immutable
class Document extends Equatable {
  /// Create a new document.
  const Document(this.paragraphs);

  /// The list of paragraphs in this document.
  final BuiltList<Paragraph> paragraphs;

  @override
  List<Object?> get props => [paragraphs];

  @override
  String toString() {
    return paragraphs.toString();
  }
}

/// A paragraph in a [Document]. Is either a [LineParagraph] for rich text,
/// or a [ParagraphEmbed] for other content.
@immutable
abstract class Paragraph {
  /// Execute [line] if this is a [LineParagraph] and [embed] if this is a
  /// [ParagraphEmbed].
  T match<T>({
    required T Function(LineParagraph) line,
    required T Function(ParagraphEmbed) embed,
  });
}

/// Immutable representation of a line of rich text in a [Document].
@immutable
class LineParagraph with EquatableMixin implements Paragraph {
  /// Create a line of rich text.
  LineParagraph({
    String? text,
    SpanList? spans,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: (text ?? '').characters,
          spans: spans ?? SpanList.empty,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a line with the text and spans of [string].
  LineParagraph.fromSpanned({
    required SpannedString string,
    List<LineModifier>? modifiers,
  }) : this.built(
          text: string.text,
          spans: string.spans,
          modifiers: modifiers?.build() ?? BuiltList<LineModifier>(),
        );

  /// Create a line with directly initialized fields.
  LineParagraph.built({
    required this.text,
    required this.spans,
    required this.modifiers,
  });

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
    required T Function(LineParagraph) line,
    required T Function(ParagraphEmbed) embed,
  }) =>
      line(this);

  /// Create a copy of this line paragraph with the given field values replaced.
  LineParagraph copyWith({
    Characters? text,
    SpanList? spans,
    BuiltList<LineModifier>? modifiers,
  }) {
    return LineParagraph.built(
      text: text ?? this.text,
      spans: spans ?? this.spans,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  @override
  String toString() {
    return spannedText.toString();
  }

  @override
  List<Object?> get props => [text, spans, modifiers];
}

/// Base class for paragraph embeds.
@immutable
abstract class ParagraphEmbed implements Paragraph {
  /// Constant base constructor for implementations.
  const ParagraphEmbed();

  @override
  T match<T>({
    required T Function(LineParagraph) line,
    required T Function(ParagraphEmbed) embed,
  }) =>
      embed(this);

  /// Create a widget that displays this embed.
  Widget createView(BuildContext context);

  /// Create a controller with this embed as its initial state.
  ParagraphEmbedController createController();
}

/// Interface for controller of a [ParagraphEmbed].
///
/// Represents the editable version of the embed.
abstract class ParagraphEmbedController {
  /// Convert the current state of the controller to a [ParagraphEmbed].
  ParagraphEmbed? toEmbed();

  /// Create an embed editor for this embed controller.
  Widget createEditor(
    BuildContext context,
    FocusNode focusNode,
  );
}

/// Base class for embeds that cannot be edited.
///
/// The widget displayed for embeds extending this class will be the same as
/// their view.
///
/// Subclasses only need to override [ParagraphEmbed.createView].
abstract class UneditableEmbed extends ParagraphEmbed
    implements ParagraphEmbedController {
  @override
  ParagraphEmbedController createController() => this;

  @override
  Widget createEditor(BuildContext context, FocusNode focusNode) =>
      createView(context);

  @override
  ParagraphEmbed? toEmbed() => this;
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
    final line = LineParagraph.fromSpanned(string: str, modifiers: modifiers);
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

/// Extension method to apply line modifiers to a widget.
extension LineModifierX on Iterable<LineModifier> {
  /// Apply the modifiers to [child], wrapping it with other widgets.
  Widget apply(BuildContext context, Widget child) {
    return fold(child, (child, mod) => mod.modify(context, child));
  }
}
