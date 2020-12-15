import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'attribute_span.dart';
import 'spanned_text_controller.dart';
import 'theme.dart';

/// Rich text represented with a [String] and a [SpanList].
@immutable
class SpannedString {
  /// Create a spanned string.
  SpannedString(this.text, this.spans);

  /// Plain text of this spanned string.
  final Characters text;

  /// Formatting of this spanned string.
  final SpanList spans;

  /// Length of this spanned string. This is equal to the length of [text].
  late int length = text.length;

  /// Creates a copy of this spanned string, but with the given fields replaced
  /// with the new values.
  SpannedString copyWith({Characters? text, SpanList? spans}) => SpannedString(
        text ?? this.text,
        spans ?? this.spans,
      );

  /// Insert text into this spanned text.
  ///
  /// The spans are shifted to accomodate for the insertion.
  SpannedString insert(int index, Characters inserted) {
    assert(index >= 0, 'Index may not be negative.');
    if (inserted.isEmpty) {
      return this;
    }

    return SpannedString(
      text.getRange(0, index) + inserted + text.getRange(index),
      spans.shift(index, inserted.length),
    );
  }

  /// Delete a part of this spanned text.
  ///
  /// The spans are shifted and deleted to accomodate for the deletion.
  SpannedString collapse({int? after, int? before}) {
    assert(after != null || before != null,
        'after and before may not both be null.');
    after ??= 0;
    before ??= length;
    final range = Range(after, before);

    if (range.isCollapsed) {
      return this;
    }

    return SpannedString(
      text.getRange(0, after) + text.getRange(before, length),
      spans.collapse(range),
    );
  }

  /// Concatenate another spanned string with this one and return the result.
  ///
  /// Touching spans with the same attribute will be merged.
  SpannedString concat(SpannedString other) {
    return SpannedString(
      text + other.text,
      other.spans
          .shift(0, text.length)
          .spans
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
        .collapse(after: diff.index, before: diff.index + diff.deleted.length)
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
}

/// Builds a [SpannedString]. Can be used fluently with cascades.
class SpannedStringBuilder {
  final StringBuffer _buffer = StringBuffer();
  SpanList _spanList = SpanList();
  final List<AttributeSpan> _activeSpans = [];

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
  void writeln(
    Object? obj, [
    Iterable<AttributeSpanTemplate> templates = const [],
  ]) {
    templates.forEach(start);
    final str = obj?.toString();
    _buffer.writeln(str);
    if (str != null) {
      _length += str.characters.length + 1;
    }
    templates.forEach(end);
  }

  /// Apply an attribute to all text, including text written after calling this
  /// method.
  void lineStyle(TextAttribute attr) {
    _spanList = _spanList.merge(AttributeSpan.fixed(attr, 0, maxSpanLength));
  }

  void _end(TextAttribute attribute) {
    final span =
        _spanList.spans.firstWhereOrNull((span) => span.attribute == attribute);
    if (span == null) {
      throw StateError(
          '''The template passed to 'end' must be activated by calling 'start' first.''');
    }

    _spanList = _spanList.merge(span.copyWith(end: _length));
    _activeSpans.remove(span);
  }

  /// Finishes building and returns the created span.
  ///
  /// The builder will be reset and can be reused.
  SpannedString build() {
    for (final span in _activeSpans) {
      _end(span.attribute);
    }

    final str = SpannedString(_buffer.toString().characters, _spanList);
    _buffer.clear();
    return str;
  }
}
