import 'dart:math' as math;

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show TextStyle, TextRange;
import 'package:meta/meta.dart' show immutable, visibleForTesting;

const _maxSpanLength = (2 << 32) - 1;

/// An attribute to apply to a span of text.
///
/// Override this class to define attributes.
/// It is very strongly recommend you override the equality operator or
/// use singletons for your attributes.
@immutable
abstract class TextAttribute {
  const TextAttribute();

  /// Apply this span to a [TextStyle].
  TextStyle apply(TextStyle style);
  // TODO Conflict resolution

  @override
  String toString() {
    return runtimeType.toString();
  }
}

/// The insert behavior of a span boundary determines how it behaves
/// when [AttributeSpan.shift] is called at its index.
enum InsertBehavior {
  inclusive,
  exclusive,
  _fixed,
}

/// Extensions for SpanAttachment.
extension InsertBehaviorExtension on InsertBehavior {
  /// Returns a string that visually indicates how this span boundary behaves
  /// when shifted at its index.
  String toBracketStr(bool before) {
    if (this == InsertBehavior.inclusive && before) {
      return ']';
    }
    if (this == InsertBehavior.inclusive && !before) {
      return '[';
    }
    if (this == InsertBehavior.exclusive) {
      return '|';
    }

    return '_';
  }
}

/// A [TextAttribute] applied to a [range] of text with rules for
/// expansion on [shift].
@immutable
class AttributeSpan extends Equatable {
  /// Create an attribute span.
  ///
  /// [range] must be valid and normalized.
  /// For an unattached span, use [AttributeSpan.fixed].
  AttributeSpan(
    this.attribute,
    this.range,
    this.startBehavior,
    this.endBehavior,
  )   : assert(range.isValid, 'Range must be valid.'),
        assert(range.isNormalized, 'Range must be normalized.'),
        assert((startBehavior == InsertBehavior._fixed) ==
            (endBehavior == InsertBehavior._fixed));

  /// Create a span that is fixed in place.
  AttributeSpan.fixed(
    TextAttribute attribute,
    TextRange range,
  ) : this(attribute, range, InsertBehavior._fixed, InsertBehavior._fixed);

  /// The attribute this span applies.
  final TextAttribute attribute;

  /// Range where this span is applied.
  final TextRange range;

  /// Behavior when [shift] is called at [TextRange.start] of [range].
  final InsertBehavior startBehavior;

  /// Behavior when [shift] is called at [TextRange.end] of [range].
  final InsertBehavior endBehavior;

  /// Returns true if this span was created with [AttributeSpan.fixed];
  bool get isFixed => startBehavior == InsertBehavior._fixed;

  /// Returns true if the [range] of this span is collapsed.
  ///
  /// See [TextRange.isCollapsed].
  bool get isCollapsed => range.isCollapsed;

  /// Inverse of [isCollapsed].
  bool get isNotCollapsed => !range.isCollapsed;

  /// Returns true if [shift] can make the [range] of this span larger.
  bool get isExpandable =>
      (startBehavior == InsertBehavior.inclusive &&
          (!isCollapsed || endBehavior == InsertBehavior.inclusive)) ||
      endBehavior == InsertBehavior.inclusive;

  /// Returns true if [shift] can't make the [range] of this span larger.
  bool get isNotExpandable => !isExpandable;

  /// Returns true if this span is not expandable and its [range] is collapsed.
  /// (see [isNotExpandable] and [TextRange.isCollapsed]).
  bool get isUseless => isNotExpandable && range.isCollapsed;

  /// True if this span is not expandable
  bool get isNotUseless => !isUseless;

  @override
  List<Object?> get props => [
        attribute,
        range,
        startBehavior,
        endBehavior,
      ];

  AttributeSpan copyWith({
    TextAttribute? attribute,
    TextRange? range,
    InsertBehavior? startAttachment,
    InsertBehavior? endAttachment,
  }) {
    return AttributeSpan(
      attribute ?? this.attribute,
      range ?? this.range,
      startAttachment ?? this.startBehavior,
      endAttachment ?? this.endBehavior,
    );
  }

  /// Return the resulting span after inserting source text at [index] with [length].
  ///
  /// If this span is collapsed [endBehavior] takes precedence to determine how
  /// this span is expanded.
  AttributeSpan shift(int index, int length) {
    if (isFixed ||
        index > range.end ||
        (index == range.end && endBehavior != InsertBehavior.inclusive)) {
      return this;
    }

    var newRange = range.copyWith(end: range.end + length);

    // If this span is collapsed we treat the shift as happening at the end
    // boundary. This way, a collapsed span with endBehavior inclusive can
    // still expand.
    if (index < this.range.start ||
        (!range.isCollapsed &&
            index == this.range.start &&
            startBehavior != InsertBehavior.inclusive)) {
      newRange = newRange.copyWith(start: range.start + length);
    }

    return copyWith(range: newRange);
  }

  /// Return the resulting span after deleting source text in [collapseRange].
  AttributeSpan? collapse(TextRange collapseRange) {
    assert(collapseRange.isValid && collapseRange.isNormalized);
    if (isFixed) {
      return this;
    } else {
      final spliced = range.splice(collapseRange);
      if (spliced != null) {
        return copyWith(range: spliced);
      }
    }
  }

  /// Returns true if this span is applied to the full range of text.
  bool isApplied(TextRange textRange) {
    assert(textRange.isValid && textRange.isNormalized);
    if (textRange.isCollapsed) {
      return willApply(textRange.start);
    }

    return this.range.contains(textRange);
  }

  /// Returns true if this span will apply to text inserted at [index].
  bool willApply(int index) {
    return (range.start < index && index < range.end) ||
        !isCollapsed && startBehavior == InsertBehavior.inclusive ||
        index == range.end && endBehavior == InsertBehavior.inclusive;
  }

  @override
  String toString() {
    return '${startBehavior.toBracketStr(true)}${range.start} ${range.end}${endBehavior.toBracketStr(false)} $attribute';
  }
}

/// A range of the source text with all attributes that are applied to it.
@immutable
class AttributeSegment {
  /// Create an attribute segment.
  const AttributeSegment(this.attributes, this.range);

  /// Attributes applied to this segment.
  final Iterable<TextAttribute> attributes;

  /// Range of text.
  final TextRange range;

  @override
  String toString() {
    return '<${range.start},${range.end}> [${attributes.map((a) => a.runtimeType).join(',')}]';
  }

  @override
  bool operator ==(other) {
    if (other is! AttributeSegment) {
      return false;
    }

    return range == other.range &&
        const DeepCollectionEquality().equals(attributes, other.attributes);
  }
}

enum _TransitionType { start, end }

@immutable
class _AttributeTransition {
  const _AttributeTransition(this.attribute, this.type, this.index);

  final TextAttribute attribute;
  final _TransitionType type;
  final int index;

  @override
  String toString() {
    return '${type.toString().padRight(5)} $index ${attribute.runtimeType}';
  }
}

/// Manages [AttributeSpan]s apart from the text to which they are to be applied.
///
/// Call [shift] when text is inserted and [collapse] when text is deleted.
///
/// Add attribute spans with [merge] and remove them with [remove].
///
/// Note that SpanList is immutable. Any mutation operation will return a new
/// SpanList.
@immutable
class SpanList {
  /// Create a SpanController.
  ///
  /// [spans] must not be out of bounds. That means [AttributeSpan.range]'s
  /// [TextRange.end] may not me larger than [length].
  SpanList([
    Iterable<AttributeSpan>? spans,
  ]) : this._sortedList(spans == null
            ? BuiltList()
            : spans
                .sorted((a, b) => a.range.start - b.range.start)
                .toBuiltList());

  SpanList._sorted(Iterable<AttributeSpan> spans)
      : this._sortedList(spans.toBuiltList());

  const SpanList._sortedList(this._spans);

  final BuiltList<AttributeSpan> _spans;

  Iterable<AttributeSpan> get spans => _spans;

  Iterable<AttributeSegment> getSegments(int end) sync* {
    // We sweep over start and end points of all spans to build the segments.
    final transitions = spans.expand((s) sync* {
      yield _AttributeTransition(
          s.attribute, _TransitionType.start, s.range.start);
      yield _AttributeTransition(s.attribute, _TransitionType.end, s.range.end);
    }).toList()
      ..sort((a, b) => a.index - b.index);

    final activeAttribs = <TextAttribute>[];
    var currentSegmentStart = 0;
    for (final transition in transitions) {
      if (transition.index > currentSegmentStart) {
        yield AttributeSegment(
          List.of(activeAttribs),
          TextRange(start: currentSegmentStart, end: transition.index),
        );
        currentSegmentStart = transition.index;
      }

      if (transition.type == _TransitionType.start) {
        activeAttribs.add(transition.attribute);
      } else {
        activeAttribs.remove(transition.attribute);
      }
    }

    if (currentSegmentStart < end) {
      yield AttributeSegment(
        const [],
        TextRange(start: currentSegmentStart, end: end),
      );
    }
  }

  /// If range is not collapsed, returns true if [attribute] is applied to the
  /// full range of text.
  ///
  /// If range is collapsed, returns the result of [willApply] for [attribute].
  bool isApplied(TextAttribute attribute, TextRange range) {
    assert(range.isValid && range.isNormalized);
    return _getSpansIn(range, attribute).any(
      (s) => s.isApplied(range.normalize()),
    );
  }

  /// Returns true if an insertion at [index] would get [attribute] applied
  /// to it due to a spans [InsertBehavior].
  bool willApply(TextAttribute attribute, int index) {
    return _getSpansIn(TextRange.collapsed(index), attribute)
        .any((s) => s.willApply(index));
  }

  Iterable<AttributeSpan> _getSpansIn(TextRange range, TextAttribute attr) =>
      _getSpans(
        spans.where((s) => s.range.touches(range)),
        attr,
      );

  static Iterable<AttributeSpan> _getSpans(
    Iterable<AttributeSpan> spans,
    TextAttribute attribute,
  ) {
    return spans.where((s) => s.attribute == attribute);
  }

  /// Add a span. Merges touching spans with the same attribute.
  ///
  /// Collapsed spans are not added. See [AttributeSpan.isCollapsed].
  ///
  /// Spans touching [span] with an equal [AttributeSpan.attribute] will be
  /// merged.
  ///
  /// Merged spans will always use [AttributeSpan.startBehavior] and
  /// [AttributeSpan.endBehavior] of the passed [span].
  /// [AttributeSpan.startBehavior] and [AttributeSpan.endBehavior] are not
  /// taken into account for merging; touching spans will always be merged.
  SpanList merge(AttributeSpan span) {
    final touching = spans.where(
        (s) => s.attribute == span.attribute && s.range.touches(span.range));
    final toMerge = touching.followedBy([span]);
    final start =
        toMerge.fold<int>(_maxSpanLength, (m, s) => math.min(m, s.range.start));
    final end = toMerge.fold<int>(-1, (m, s) => math.max(m, s.range.end));
    final merged = span.copyWith(
      range: TextRange(start: start, end: end),
    );
    if (merged.isNotCollapsed) {
      return SpanList(
        _spans.whereNot(toMerge.contains).followedBy([merged]).sorted(
            (a, b) => a.range.start - b.range.start),
      );
    } else {
      return SpanList._sorted(_spans.whereNot(touching.contains));
    }
  }

  /// Remove [span].
  SpanList remove(AttributeSpan span) {
    return SpanList._sorted(_spans.where((s) => s != span));
  }

  /// Remove all spans with the given attribute.
  SpanList removeAll(TextAttribute attribute) {
    return SpanList._sorted(_spans.where((s) => s.attribute != attribute));
  }

  /// Remove all spans with the given attribute from [range].
  ///
  /// This method can remove parts of spans if the range does not cover
  /// the range of matching spans.
  SpanList removeFrom(TextRange range, TextAttribute attribute) {
    return SpanList(
      _spans.rebuild(
        (b) => b.expand(
          (s) sync* {
            if (s.attribute != attribute || !s.range.overlaps(range)) {
              yield s;
            } else {
              if (s.range.start < range.start) {
                yield s.copyWith(
                    range: TextRange(start: s.range.start, end: range.start));
              }
              if (range.end < s.range.end) {
                yield s.copyWith(
                    range: TextRange(start: range.end, end: s.range.end));
              }
            }
          },
        ),
      ),
    );
  }

  /// Shift spans with an insertion at [index] with the given [length].
  SpanList shift(int index, int length) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'Index must be non-negative.');
    }
    if (length == 0) {
      return this;
    }
    return SpanList(_spans.map((s) => s.shift(index, length)));
  }

  /// Collapse span with a deletion at [range].
  SpanList collapse(TextRange range) {
    if (!range.isValid || !range.isNormalized) {
      throw ArgumentError.value(
          range, 'range', 'Range must be valid and normalized.');
    }

    if (range.isCollapsed) {
      return this;
    }
    return SpanList(_spans.expand((s) sync* {
      final collapsedSpan = s.collapse(range);
      if (collapsedSpan != null && collapsedSpan.isNotCollapsed) {
        yield collapsedSpan;
      }
    }));
  }
}

/// Extensions for spans on text range.
@visibleForTesting
extension SpanRangeExtensions on TextRange {
  int get length {
    assert(isValid && isNormalized);
    return end - start;
  }

  TextRange copyWith({int? start, int? end}) =>
      TextRange(start: start ?? this.start, end: end ?? this.end);

  bool misses(TextRange other) {
    assert(isValid && isNormalized);
    return start > other.end || end < other.start;
  }

  bool touches(TextRange other) {
    assert(isValid && isNormalized);
    return !misses(other);
  }

  bool overlaps(TextRange other) {
    return start < other.end && end > other.start;
  }

  bool contains(TextRange other) {
    assert(isValid && isNormalized);
    return start <= other.start && other.end <= end;
  }

  TextRange merge(TextRange other) {
    assert(isValid && isNormalized);
    assert(touches(other), 'Ranges must touch to be merged.');
    return TextRange(
      start: math.min(start, other.start),
      end: math.max(end, other.end),
    );
  }

  TextRange normalize() {
    if (this.isNormalized) {
      return this;
    }

    return TextRange(start: end, end: start);
  }

  // Get what's left after deleting a range from this range.
  TextRange? splice(TextRange removedSegment) {
    assert(removedSegment.isValid && removedSegment.isNormalized);
    if (this.start <= removedSegment.start && removedSegment.end <= this.end) {
      // deletion inside this range
      return copyWith(end: this.end - removedSegment.length);
    }
    if (removedSegment.start >= this.end) {
      // deletion after this range
      return this;
    }
    if (removedSegment.end <= this.start) {
      // deletion before this range
      return TextRange(
          start: start - removedSegment.length,
          end: end - removedSegment.length);
    }
    if (removedSegment.start <= this.start && removedSegment.end <= this.end) {
      // deletion with the start of this range
      return TextRange(
          start: removedSegment.start, end: this.end - removedSegment.length);
    }
    if (this.start <= removedSegment.start && this.end <= removedSegment.end) {
      // deletion with the end of this range
      return copyWith(end: removedSegment.start);
    }
    if (removedSegment.start <= this.start && this.end <= removedSegment.end) {
      // deletion of the full range
      return null;
    }
  }
}
