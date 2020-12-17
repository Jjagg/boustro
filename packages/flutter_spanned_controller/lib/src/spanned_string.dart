import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'attribute_span.dart';
import 'spanned_text_controller.dart';
import 'theme.dart';

/// Rich text represented with a [String] and a [SpanList].
@immutable
class SpannedString extends Equatable {
  /// Create a spanned string.
  SpannedString(String text, [SpanList? spans])
      : this.chars(text.characters, spans ?? SpanList());

  /// Create an empty spanned string.
  SpannedString.empty() : this('', SpanList());

  /// Create a spanned string.
  SpannedString.chars(this.text, this.spans);

  /// Plain text of this spanned string.
  final Characters text;

  /// Formatting of this spanned string.
  final SpanList spans;

  /// Length of this spanned string. This is equal to the length of [text].
  late final int length = text.length;

  /// Creates a copy of this spanned string, but with the given fields replaced
  /// with the new values.
  SpannedString copyWith({Characters? text, SpanList? spans}) =>
      SpannedString.chars(
        text ?? this.text,
        spans ?? this.spans,
      );

  /// Insert text into this spanned text.
  ///
  /// The spans are shifted to accomodate for the insertion.
  SpannedString insert(int index, Characters inserted) {
    if (index < 0 || index > length) {
      throw RangeError.index(
          index, text, 'index', 'Index must be inside text range.', length);
    }
    if (inserted.isEmpty) {
      return this;
    }

    return SpannedString.chars(
      text.getRange(0, index) + inserted + text.getRange(index),
      spans.shift(index, inserted.length),
    );
  }

  /// Delete a part of this spanned text.
  ///
  /// The spans are shifted and deleted to accomodate for the deletion.
  /// End is exlusive.
  SpannedString collapse({int? start, int? end}) {
    if (start == null && end == null) {
      throw ArgumentError('start and end may not both be null.');
    }
    start ??= 0;
    end ??= length;

    if (start < 0 || end > length) {
      throw RangeError('start and end must be inside text range.');
    }
    if (end < start) {
      throw ArgumentError('end may not come before start.');
    }

    final range = Range(start, end);

    if (range.isCollapsed) {
      return this;
    }

    return SpannedString.chars(
      text.getRange(0, start) + text.getRange(end, length),
      spans.collapse(range),
    );
  }

  /// Concatenate another spanned string with this one and return the result.
  ///
  /// Touching spans with the same attribute will be merged.
  SpannedString concat(SpannedString other) {
    return SpannedString.chars(
      text + other.text,
      other.spans
          .shift(0, text.length)
          .iter
          .fold(spans, (ls, s) => ls.merge(s)),
    );
  }

  /// Apply [diff] to this spanned string and return the result.
  ///
  /// This method will first [collapse] [StringDiff.deleted] and then [insert]
  /// [StringDiff.inserted].
  SpannedString applyDiff(StringDiff diff) {
    // ignore: unnecessary_this
    return this
        .collapse(start: diff.index, end: diff.index + diff.deleted.length)
        .insert(diff.index, diff.inserted);
  }

  /// Apply the attributes to [text] and return the resulting [TextSpan].
  ///
  /// See [AttributeSegmentsExtensions].
  TextSpan buildTextSpans({
    required TextStyle style,
    AttributeThemeData? attributeTheme,
    Map<TextAttributeValue, GestureRecognizer>? recognizers,
  }) {
    if (spans.iter.isEmpty) {
      return TextSpan(text: text.string, style: style);
    }

    final segments = spans.getSegments(text);
    return segments.buildTextSpans(
      style: style,
      attributeTheme: attributeTheme,
      recognizers: recognizers,
    );
  }

  @override
  String toString() {
    return '$text <$spans>';
  }

  @override
  List<Object?> get props => [text, spans];
}

/// Builds a [SpannedString]. Can be used fluently with cascades.
class SpannedStringBuilder {
  final StringBuffer _buffer = StringBuffer();
  SpanList _spans = SpanList();
  final Set<AttributeSpan> _activeSpans = {};

  int _length = 0;

  /// Format written text with [template] until [end] is called for the passed
  /// template.
  void start(AttributeSpanTemplate template) {
    _activeSpans.add(template.toSpan(_length, maxSpanLength));
  }

  /// Stop formatting added text with [template].
  ///
  /// Throws a [StateError] if [start] was not first called for [template].
  void end(AttributeSpanTemplate template) {
    _end(template.attribute);
  }

  /// Write text to the internal string buffer.
  ///
  /// Applies any active templates (templates for which [start] was called, but
  /// [end] was not yet called) and the additional templates passed.
  void write(
    Object? obj, [
    Iterable<AttributeSpanTemplate> templates = const [],
  ]) {
    templates.forEach(start);
    final str = obj?.toString();
    _buffer.write(str);
    if (str != null) {
      _length += str.characters.length;
    }
    templates.forEach(end);
  }

  /// Write text to the internal string buffer, followed by a newline.
  ///
  /// Applies any active templates (templates for which [start] was called, but
  /// [end] was not yet called) and the additional templates passed.
  ///
  /// If [obj] is null or [obj.toString()] returns null only a newline is
  /// written.
  void writeln([
    Object? obj,
    Iterable<AttributeSpanTemplate> templates = const [],
  ]) {
    templates.forEach(start);
    final str = obj?.toString() ?? '';
    _buffer.writeln(str);
    _length += str.characters.length + 1;
    templates.forEach(end);
  }

  /// Apply an attribute to all text, including text written after calling this
  /// method.
  void lineStyle(TextAttribute attr) {
    _spans = _spans.merge(AttributeSpan.fixed(attr, 0, maxSpanLength));
  }

  void _end(TextAttribute attribute) {
    final span =
        _activeSpans.firstWhereOrNull((span) => span.attribute == attribute);
    if (span == null) {
      throw StateError(
          '''The template passed to 'end' must be activated by calling 'start' first.''');
    }

    _spans = _spans.merge(span.copyWith(end: _length));
    _activeSpans.remove(span);
  }

  /// Finishes building and returns the created span.
  ///
  /// The builder will be reset and can be reused.
  SpannedString build() {
    for (final span in _activeSpans) {
      _spans = _spans.merge(span.copyWith(end: _length));
    }
    _activeSpans.clear();

    final str = SpannedString(_buffer.toString(), _spans);
    _buffer.clear();
    return str;
  }
}
