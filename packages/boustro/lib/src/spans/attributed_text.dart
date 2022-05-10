import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'attribute_span.dart';
import 'attributed_text_editing_controller.dart';

/// Rich text represented with a [String] and a [AttributeSpanList].
@immutable
class AttributedText extends Equatable {
  /// Create a spanned string.
  AttributedText(String text, [AttributeSpanList? spans])
      : this.chars(text.characters, spans ?? AttributeSpanList.empty);

  /// Create a spanned string.
  // The analyzer lets this be const (it shouldn't), but running it as const throws.
  // ignore: prefer_const_constructors_in_immutables
  AttributedText.chars(this.text, this.spans) : length = text.length;

  const AttributedText._empty()
      : text = Characters.empty,
        spans = AttributeSpanList.empty,
        length = 0;

  /// An empty spanned string.
  static const AttributedText empty = AttributedText._empty();

  /// Plain text of this spanned string.
  final Characters text;

  /// Formatting of this spanned string.
  final AttributeSpanList spans;

  /// Length of this spanned string. This is equal to the length of [text].
  final int length;

  /// Creates a copy of this spanned string, but with the given fields replaced
  /// with the new values.
  AttributedText copyWith({Characters? text, AttributeSpanList? spans}) =>
      AttributedText.chars(
        text ?? this.text,
        spans ?? this.spans,
      );

  /// Insert text into this spanned text.
  ///
  /// The spans are shifted to accomodate for the insertion.
  AttributedText insert(int index, Characters inserted) {
    if (index < 0 || index > length) {
      throw RangeError.index(
          index, text, 'index', 'Index must be inside text range.', length);
    }
    if (inserted.isEmpty) {
      return this;
    }

    return AttributedText.chars(
      text.getRange(0, index) + inserted + text.getRange(index),
      spans.shift(index, inserted.length),
    );
  }

  /// Delete a part of this spanned text.
  ///
  /// The spans are shifted and deleted to accomodate for the deletion.
  /// End is exlusive.
  AttributedText collapse({int? start, int? end}) {
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

    return AttributedText.chars(
      text.getRange(0, start) + text.getRange(end, length),
      spans.collapse(range),
    );
  }

  /// Concatenate another spanned string with this one and return the result.
  ///
  /// Touching spans with the same attribute will be merged.
  AttributedText concat(AttributedText other) {
    return AttributedText.chars(
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
  AttributedText applyDiff(StringDiff diff) {
    // ignore: unnecessary_this
    return this
        .collapse(start: diff.index, end: diff.index + diff.deleted.length)
        .insert(diff.index, diff.inserted);
  }

  /// Apply the attributes to [text] and return the resulting [TextSpan].
  ///
  /// See [AttributeSegmentsExtensions].
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    AttributeGestureMapper? gestureMapper,
  }) {
    if (spans.iter.isEmpty) {
      return TextSpan(text: text.string, style: style);
    }

    final segments = spans.getSegments(text);
    return segments.buildTextSpan(
      context: context,
      style: style,
      gestureMapper: gestureMapper,
    );
  }

  @override
  String toString() {
    return '$text <$spans>';
  }

  @override
  List<Object?> get props => [text, spans];
}

/// Builds an [AttributedText]. Can be used fluently.
class AttributedTextBuilder {
  final StringBuffer _buffer = StringBuffer();
  AttributeSpanList _spans = AttributeSpanList.empty;
  final Set<AttributeSpan> _activeSpans = {};

  int _length = 0;

  /// Format written text with [attribute] until [end] is called for the passed
  /// attribute.
  AttributedTextBuilder start(TextAttribute attribute) {
    _activeSpans.add(AttributeSpan(attribute, _length, maxSpanLength));
    return this;
  }

  /// Stop formatting added text with [attribute].
  ///
  /// Throws a [StateError] if [start] was not first called for [attribute].
  AttributedTextBuilder end(TextAttribute attribute) {
    _end(attribute);
    return this;
  }

  /// Write text to the internal string buffer.
  ///
  /// Applies any active attributes (attributes for which [start] was called,
  /// but [end] was not yet called) and the additional attributes passed.
  AttributedTextBuilder write(
    Object? obj, [
    Iterable<TextAttribute> attributes = const [],
  ]) {
    attributes.forEach(start);
    final str = obj?.toString();
    _buffer.write(str);
    if (str != null) {
      _length += str.characters.length;
    }
    attributes.forEach(end);
    return this;
  }

  /// Write text to the internal string buffer, followed by a newline.
  ///
  /// Applies any active attributes (attributes for which [start] was called,
  /// but [end] was not yet called) and the additional attributes passed.
  ///
  /// If [obj] is null or [obj.toString()] returns null only a newline is
  /// written.
  AttributedTextBuilder writeln([
    Object? obj,
    Iterable<TextAttribute> attributes = const [],
  ]) {
    attributes.forEach(start);
    final str = obj?.toString() ?? '';
    _buffer.writeln(str);
    _length += str.characters.length + 1;
    attributes.forEach(end);
    return this;
  }

  /// Apply an attribute to all text, including text written after calling this
  /// method. Typically used for attributes with [SpanExpandRules.fixed].
  AttributedTextBuilder lineStyle(TextAttribute attr) {
    _spans = _spans.merge(AttributeSpan(attr, 0, maxSpanLength));
    return this;
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
  AttributedText build() {
    for (final span in _activeSpans) {
      _spans = _spans.merge(span.copyWith(end: _length));
    }
    _activeSpans.clear();

    final str = AttributedText(_buffer.toString(), _spans);
    _buffer.clear();
    return str;
  }
}
