import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'attribute_span.dart';
import 'spanned_text_controller.dart';

/// Rich text represented with a [String] and a [SpanList].
@immutable
class SpannedString {
  /// Create a spanned string.
  const SpannedString(this.text, this.spans);

  /// Plain text of this spanned string.
  final String text;

  /// Formatting of this spanned string.
  final SpanList spans;

  /// Length of this spanned string. This is equal to the length of [text].
  int get length => text.length;

  /// Creates a copy of this spanned string, but with the given fields replaced
  /// with the new values.
  SpannedString copyWith({String? text, SpanList? spans}) => SpannedString(
        text ?? this.text,
        spans ?? this.spans,
      );

  /// Insert text into this spanned text.
  ///
  /// The spans are shifted to accomodate for the insertion.
  SpannedString insert(int index, String inserted) {
    assert(index >= 0, 'Index may not be negative.');
    if (inserted.isEmpty) {
      return this;
    }

    return SpannedString(
      text.substring(0, index) + inserted + text.substring(index),
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
    before ??= text.length;
    final range = TextRange(start: after, end: before);

    if (range.isCollapsed) {
      return this;
    }

    return SpannedString(
      text.substring(0, after) + text.substring(before),
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
    Map<TextAttribute, GestureRecognizer>? recognizers,
  }) {
    final segments = spans.getSegments(text.length);
    return segments.buildTextSpans(
        text: text, style: style, recognizers: recognizers);
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

  /// Format written text with [template] until [end] is called for the passed
  /// template.
  void start(AttributeSpanTemplate template) {
    _activeSpans.add(template.toSpan(_buffer.length, maxSpanLength));
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
    _buffer.write(obj);
    templates.forEach(end);
  }

  /// Write text to the internal string buffer, followed by a newline.
  ///
  /// Applies any active templates (templates for which [start] was called, but
  /// [end] was not yet called) and the additional templates passed.
  void writeln(Object? obj,
      [Iterable<AttributeSpanTemplate> templates = const []]) {
    templates.forEach(start);
    _buffer.writeln(obj);
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

    _spanList = _spanList.merge(span.copyWith(end: _buffer.length));
    _activeSpans.remove(span);
  }

  /// Finishes building and returns the created span.
  ///
  /// The builder will be reset and can be reused.
  SpannedString build() {
    for (final span in _activeSpans) {
      _end(span.attribute);
    }

    final str = SpannedString(_buffer.toString(), _spanList);
    _buffer.clear();
    return str;
  }
}
