import 'dart:math' as math;

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' show immutable, visibleForTesting;

const _maxSpanLength = (2 << 32) - 1;

/// An attribute to apply to a span of text.
///
/// Applying an attribute to a span of text can format or add gesture handlers
/// to that span.
///
/// If you extend this class it is very strongly recommended you override [props]
/// or the equality operator or use a singleton for the attribute.
@immutable
class TextAttribute extends Equatable {
  /// Constant constructor for text attributes.
  const TextAttribute({
    this.debugName,
    this.style,
    this.onTap,
    this.onSecondaryTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  /// Name of the attribute. Used only for debugging, does not affect equality.
  final String? debugName;

  /// Style to apply with this attribute.
  final TextStyle? style;

  /// Callback when tapping the span.
  final GestureTapCallback? onTap;

  /// Callback when secondary tapping the span (e.g. right mouse button).
  final GestureTapCallback? onSecondaryTap;

  /// Callback when double tapping the span.
  final GestureTapCallback? onDoubleTap;

  /// Callback when long pressing the span.
  final GestureLongPressCallback? onLongPress;

  /// True if any of the gesture callbacks is not null.
  bool get hasGestures =>
      onTap != null ||
      onSecondaryTap != null ||
      onDoubleTap != null ||
      onLongPress != null;

  // TODO Conflict resolution

  @override
  String toString() {
    return debugName ?? super.toString();
  }

  @override
  List<Object?> get props => [
        style,
        onTap,
        onSecondaryTap,
        onDoubleTap,
        onLongPress,
      ];
}

/// The insert behavior of a span boundary determines how it behaves
/// when [AttributeSpan.shift] is called at its index.
enum InsertBehavior {
  /// The span will expand at this boundary.
  inclusive,

  /// The span will not expand at this boundary.
  exclusive,
  _fixed,
}

/// Data object that holds [InsertBehavior] for the start and end boundaries.
class FullInsertBehavior {
  /// Create a full insert behavior object.
  const FullInsertBehavior(this.start, this.end);

  /// Behavior at the start of the span.
  final InsertBehavior start;

  /// Behavior at the end of the span.
  final InsertBehavior end;
}

/// Extensions for SpanAttachment.
extension InsertBehaviorExtension on InsertBehavior {
  /// Returns a string that visually indicates how this span boundary behaves
  /// when shifted at its index.
  // ignore: avoid_positional_boolean_parameters
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
        assert(
            (startBehavior == InsertBehavior._fixed) ==
                (endBehavior == InsertBehavior._fixed),
            'Start and end behavior must either both be fixed or neither may be fixed.');

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

  /// Creates a copy of this attribute span with the given fields replaced with
  /// the new values.
  AttributeSpan copyWith({
    TextAttribute? attribute,
    TextRange? range,
    InsertBehavior? startBehavior,
    InsertBehavior? endBehavior,
  }) {
    return AttributeSpan(
      attribute ?? this.attribute,
      range ?? this.range,
      startBehavior ?? this.startBehavior,
      endBehavior ?? this.endBehavior,
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
    if (index < range.start ||
        (!range.isCollapsed &&
            index == range.start &&
            startBehavior != InsertBehavior.inclusive)) {
      newRange = newRange.copyWith(start: range.start + length);
    }

    return copyWith(range: newRange);
  }

  /// Return the resulting span after deleting source text in [collapseRange].
  AttributeSpan? collapse(TextRange collapseRange) {
    assert(collapseRange.isValid && collapseRange.isNormalized,
        'Range must be valid and normalized.');
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
    assert(textRange.isValid && textRange.isNormalized,
        'Range must be valid and normalized.');
    if (textRange.isCollapsed) {
      return willApply(textRange.start);
    }

    return range.contains(textRange);
  }

  /// Returns true if this span will apply to text inserted at [index].
  bool willApply(int index) {
    return (range.start < index && index < range.end) ||
        !isCollapsed && startBehavior == InsertBehavior.inclusive ||
        index == range.end && endBehavior == InsertBehavior.inclusive;
  }

  @override
  String toString() {
    return '(${startBehavior.toBracketStr(true)}${range.start} ${range.end}${endBehavior.toBracketStr(false)} $attribute)';
  }
}

/// A range of the source text with all attributes that are applied to it.
@immutable
class AttributeSegment extends Equatable {
  /// Create an attribute segment.
  const AttributeSegment(this.attributes, this.range);

  /// Create an attribute segment.
  AttributeSegment.from(Iterable<TextAttribute> attributes, this.range)
      : attributes = attributes.toBuiltList();

  /// Attributes applied to this segment.
  final BuiltList<TextAttribute> attributes;

  /// Range of text.
  final TextRange range;

  @override
  String toString() {
    return '<${range.start},${range.end}> [${attributes.map((a) => a.runtimeType).join(',')}]';
  }

  @override
  List<Object?> get props => [range, attributes];
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
class SpanList extends Equatable {
  /// Create a SpanList.
  SpanList([
    Iterable<AttributeSpan>? spans,
  ]) : this._sortedList(spans == null
            ? BuiltList()
            : spans.sorted((a, b) => a.range.start - b.range.start).build());

  /// Create a SpanList from segments.
  ///
  /// Segments will be merged to create the [spans].
  /// [getInsertBehavior] is used to determine insert behavior
  /// for created spans, since [AttributeSegment] does not
  /// store that information.
  factory SpanList.fromSegments(
    Iterable<AttributeSegment> segments,
    FullInsertBehavior Function(TextAttribute) getInsertBehavior,
  ) {
    return segments.fold<SpanList>(SpanList(), (list, segment) {
      return segment.attributes.fold<SpanList>(list, (list, attr) {
        final insertBehavior = getInsertBehavior(attr);
        final span = AttributeSpan(
          attr,
          segment.range,
          insertBehavior.start,
          insertBehavior.end,
        );
        return list.merge(span);
      });
    });
  }

  SpanList._sorted(Iterable<AttributeSpan> spans)
      : this._sortedList(spans.toBuiltList());

  const SpanList._sortedList(this._spans);

  final BuiltList<AttributeSpan> _spans;

  /// Get the spans in this list.
  Iterable<AttributeSpan> get spans => _spans;

  /// Get an iterator of the segments for this list.
  ///
  /// Segments represent the formatting of the text in a different way than
  /// spans.
  // TODO proper segments explanation
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
          BuiltList(activeAttribs),
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
        BuiltList(),
        TextRange(start: currentSegmentStart, end: end),
      );
    }
  }

  /// If range is not collapsed, returns true if [attribute] is applied to the
  /// full range of text.
  ///
  /// If range is collapsed, returns the result of [willApply] for [attribute].
  bool isApplied(TextAttribute attribute, TextRange range) {
    assert(range.isValid && range.isNormalized,
        'Range must be valid and normalized.');
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

  @override
  String toString() {
    return spans.join(', ');
  }

  @override
  List<Object?> get props => [_spans];
}

/// Extensions for spans on text range.
@visibleForTesting
extension SpanRangeExtensions on TextRange {
  /// Get the length of this range. Equal to [end] - [start].
  int get length {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    return end - start;
  }

  /// Copy this range with the given fields replaced replaced with the new
  /// values.
  TextRange copyWith({int? start, int? end}) =>
      TextRange(start: start ?? this.start, end: end ?? this.end);

  /// True if this range does not touch or overlap [other].
  bool misses(TextRange other) {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    return start > other.end || end < other.start;
  }

  /// True if this range touches [other], i.e. it either overlaps or one of its
  /// endpoints is equal to an endpoint of [other].
  bool touches(TextRange other) {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    return !misses(other);
  }

  /// True of this range overlaps with [other].
  bool overlaps(TextRange other) {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    return start < other.end && end > other.start;
  }

  /// True if this range fully contains [other] (non-strictly).
  bool contains(TextRange other) {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    return start <= other.start && other.end <= end;
  }

  /// Combine a touching range with this one and return the result.
  TextRange merge(TextRange other) {
    assert(isValid && isNormalized, 'Range must be valid and normalized.');
    assert(touches(other), 'Ranges must touch to be merged.');
    return TextRange(
      start: math.min(start, other.start),
      end: math.max(end, other.end),
    );
  }

  /// Normalize this range. If [isNormalized] is false this returns a range
  /// with [start] and [end] flipped.
  ///
  /// If this range is invalid this returns an identical range.
  TextRange normalize() {
    if (isNormalized) {
      return this;
    }

    return TextRange(start: end, end: start);
  }

  /// Get the result after deleting a range from this range.
  TextRange? splice(TextRange removedSegment) {
    assert(removedSegment.isValid && removedSegment.isNormalized,
        'Range must be valid and normalized.');
    if (start <= removedSegment.start && removedSegment.end <= end) {
      // deletion inside this range
      return copyWith(end: end - removedSegment.length);
    }
    if (removedSegment.start >= end) {
      // deletion after this range
      return this;
    }
    if (removedSegment.end <= start) {
      // deletion before this range
      return TextRange(
          start: start - removedSegment.length,
          end: end - removedSegment.length);
    }
    if (removedSegment.start <= start && removedSegment.end <= end) {
      // deletion with the start of this range
      return TextRange(
          start: removedSegment.start, end: end - removedSegment.length);
    }
    if (start <= removedSegment.start && end <= removedSegment.end) {
      // deletion with the end of this range
      return copyWith(end: removedSegment.start);
    }
    if (removedSegment.start <= start && end <= removedSegment.end) {
      // deletion of the full range
      return null;
    }
  }
}
