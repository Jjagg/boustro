import 'dart:math' as math;

import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'spanned_string.dart';
import 'theme.dart';

/// Maximum length of a span.
///
/// This is a pretty arbitrary large number.
/// Use this for virtually infinite size spans.
const maxSpanLength = (2 << 32) - 1;

/// An attribute to apply to a span of text.
///
/// Applying an attribute to a span of text can format or add gesture handlers
/// to that span.
///
/// If you extend this class it is very strongly recommended you override
/// the equality operator or use a singleton for the attribute, because
/// the span system uses equality tests for operations like [SpanList.merge]
/// and [SpanList.isApplied]/[SpanList.willApply].
abstract class TextAttribute {
  /// Base constant constructor for inheritors that have a constant constructor.
  const TextAttribute();

  /// Constructor for attributes that always return the same value in [resolve].
  factory TextAttribute.simple({
    String? debugName,
    TextStyle? style,
    GestureTapCallback? onTap,
    GestureTapCallback? onSecondaryTap,
    GestureTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
  }) {
    return _SimpleTextAttribute(TextAttributeValue(
      debugName: debugName,
      style: style,
      onTap: onTap,
      onSecondaryTap: onSecondaryTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
    ));
  }

  /// Returns a text attribute value that can depend on [theme].
  TextAttributeValue resolve(AttributeThemeData theme);
}

/// A text attribute with a value that does not depend on a [BuildContext].
class _SimpleTextAttribute extends TextAttribute with EquatableMixin {
  /// Create a simple text attribute.
  const _SimpleTextAttribute(this.value);

  /// The value that will be returned by [resolve].
  final TextAttributeValue value;

  @override
  TextAttributeValue resolve(AttributeThemeData theme) => value;

  @override
  List<Object?> get props => [value];
}

/// Style and gesture handlers that can be applied to a [TextSpan].
///
/// Produced by [TextAttribute.resolve].
@immutable
class TextAttributeValue extends Equatable {
  /// Constant constructor for text attributes.
  const TextAttributeValue({
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

/// A range with a [start] and [end] index.
class Range extends Equatable {
  /// Create a range.
  const Range(this.start, this.end)
      : assert(start >= 0 && end >= 0, 'Start and end may not be negative.'),
        assert(start <= end, 'End must be larger than or equal to start.');

  /// Create a range with the same start and end point.
  const Range.collapsed(int index) : this(index, index);

  /// Start of the range.
  final int start;

  /// End of the range.
  final int end;

  /// Create a range with the given [start] and the end from this range.
  Range withStart(int start) => Range(start, end);

  /// Create a range with the start from this range and the given [end].
  Range withEnd(int end) => Range(start, end);

  /// True if `start == end`;
  bool get isCollapsed => start == end;

  /// Get the size of this range. Equal to [end] - [start].
  int get size {
    return end - start;
  }

  /// Copy this range with the given fields replaced replaced with the new
  /// values.
  Range copyWith({int? start, int? end}) =>
      Range(start ?? this.start, end ?? this.end);

  /// True if this range does not touch or overlap [other].
  bool misses(Range other) {
    return start > other.end || end < other.start;
  }

  /// True if this range touches [other], i.e. it either overlaps or one of its
  /// endpoints is equal to an endpoint of [other].
  bool touches(Range other) {
    return !misses(other);
  }

  /// True of this range overlaps with [other].
  bool overlaps(Range other) {
    return start < other.end && end > other.start;
  }

  /// True if this range fully contains [other] (non-strictly).
  bool contains(Range other) {
    return start <= other.start && other.end <= end;
  }

  /// Combine a touching range with this one and return the result.
  Range merge(Range other) {
    assert(touches(other), 'Ranges must touch to be merged.');
    return Range(
      math.min(start, other.start),
      math.max(end, other.end),
    );
  }

  // Normalize this range. If [isNormalized] is false this returns a range
  // with [start] and [end] flipped.
  //
  // If this range is invalid this returns an identical range.
  //Range normalize() {
  //  if (isNormalized) {
  //    return this;
  //  }

  //  return TextRange(start: end, end: start);
  //}

  /// Get the result after deleting a range from this range.
  Range? splice(Range removedSegment) {
    if (start <= removedSegment.start && removedSegment.end <= end) {
      // deletion inside this range
      return withEnd(end - removedSegment.size);
    }
    if (removedSegment.start >= end) {
      // deletion after this range
      return this;
    }
    if (removedSegment.end <= start) {
      // deletion before this range
      return Range(start - removedSegment.size, end - removedSegment.size);
    }
    if (removedSegment.start <= start && removedSegment.end <= end) {
      // deletion with the start of this range
      return Range(removedSegment.start, end - removedSegment.size);
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

  @override
  List<Object?> get props => [start, end];
}

/// A [TextAttribute] applied to a [range] of text with rules for
/// expansion on [shift].
@immutable
class AttributeSpan extends Equatable {
  /// Create an attribute span.
  ///
  /// [range] must be valid and normalized.
  /// For an unattached span, use [AttributeSpan.fixed].
  const AttributeSpan(
    this.attribute,
    this.start,
    this.end,
    this.startBehavior,
    this.endBehavior,
  )   : assert(start >= 0 && end >= 0, 'Range must be valid.'),
        assert(start <= end, 'Range must be normalized.'),
        assert(
            (startBehavior == InsertBehavior._fixed) ==
                (endBehavior == InsertBehavior._fixed),
            'Start and end behavior must either both be fixed or neither may be fixed.');

  /// Create a span that is fixed in place.
  const AttributeSpan.fixed(TextAttribute attribute, int start, int end)
      : this(attribute, start, end, InsertBehavior._fixed,
            InsertBehavior._fixed);

  /// The attribute this span applies.
  final TextAttribute attribute;

  /// Start of the range of this span.
  final int start;

  /// End of the range of this span.
  final int end;

  /// Range where this span is applied.
  Range get range => Range(start, end);

  /// Size of the range of this span.
  int get size => end - start;

  /// Behavior when [shift] is called at the [start] of this span.
  final InsertBehavior startBehavior;

  /// Behavior when [shift] is called at the [end] of this span.
  final InsertBehavior endBehavior;

  /// Returns true if this span was created with [AttributeSpan.fixed];
  bool get isFixed => startBehavior == InsertBehavior._fixed;

  /// Returns true if the [range] of this span is collapsed.
  ///
  /// See [Range.isCollapsed].
  bool get isCollapsed => start == end;

  /// Inverse of [isCollapsed].
  bool get isNotCollapsed => !isCollapsed;

  /// Returns true if [shift] can make the [range] of this span larger.
  bool get isExpandable =>
      (startBehavior == InsertBehavior.inclusive &&
          (!isCollapsed || endBehavior == InsertBehavior.inclusive)) ||
      endBehavior == InsertBehavior.inclusive;

  /// Returns true if [shift] can't make the [range] of this span larger.
  bool get isNotExpandable => !isExpandable;

  /// Returns true if this span is not expandable and its [range] is collapsed.
  /// (see [isNotExpandable] and [Range.isCollapsed]).
  bool get isUseless => isNotExpandable && isCollapsed;

  /// True if this span is not expandable
  bool get isNotUseless => !isUseless;

  @override
  List<Object?> get props => [
        attribute,
        start,
        end,
        startBehavior,
        endBehavior,
      ];

  /// Creates a copy of this attribute span with the given fields replaced with
  /// the new values.
  AttributeSpan copyWith({
    TextAttribute? attribute,
    int? start,
    int? end,
    InsertBehavior? startBehavior,
    InsertBehavior? endBehavior,
  }) {
    return AttributeSpan(
      attribute ?? this.attribute,
      start ?? this.start,
      end ?? this.end,
      startBehavior ?? this.startBehavior,
      endBehavior ?? this.endBehavior,
    );
  }

  /// Return the resulting span after inserting source text at [index] with [length].
  ///
  /// If this span is collapsed and [endBehavior] is [InsertBehavior.inclusive],
  /// [startBehavior] is treated as [InsertBehavior.inclusive] always.
  /// I.e. a shift at the index of a collapsed span \[\[ will result in \[o\[. Note
  /// that the start is expanded even though the insert behavior is set to
  /// [InsertBehavior.exclusive]. Because of this exception a collapsed span
  /// with [endBehavior] inclusive can still expand.
  // TODO this behavior should probably be symmetric, though start inclusive
  // spans are not very useful in practice...
  // Or maybe we can get rid of it altogether since the controller now has the
  // override mechanism and collapsed spans are deleted by SpanList.
  AttributeSpan shift(int index, int length) {
    if (isFixed ||
        index > end ||
        (index == end && endBehavior != InsertBehavior.inclusive)) {
      return this;
    }

    final newEnd = end + length;

    final startBehavior = isCollapsed && endBehavior == InsertBehavior.inclusive
        ? InsertBehavior.inclusive
        : this.startBehavior;

    // If this span is collapsed we treat the shift as happening at the end
    // boundary. This way, a collapsed span with endBehavior inclusive can
    // still expand.
    if (index > start ||
        (index == start && startBehavior == InsertBehavior.inclusive)) {
      return copyWith(end: newEnd);
    }

    final newStart = start + length;
    return copyWith(start: newStart, end: newEnd);
  }

  /// Return the resulting span after deleting source text in [collapseRange].
  AttributeSpan? collapse(Range collapseRange) {
    if (isFixed) {
      return this;
    } else {
      final spliced = range.splice(collapseRange);
      if (spliced != null) {
        return copyWith(start: spliced.start, end: spliced.end);
      }
    }
  }

  /// Returns true if this span is applied to the full range of text.
  bool isApplied(Range textRange) {
    if (textRange.isCollapsed) {
      return willApply(textRange.start);
    }

    return range.contains(textRange);
  }

  /// Returns true if this span will apply to text inserted at [index].
  bool willApply(int index) {
    return (start < index && index < end) ||
        (!isCollapsed &&
            index == start &&
            startBehavior == InsertBehavior.inclusive) ||
        (index == end && endBehavior == InsertBehavior.inclusive);
  }

  @override
  String toString() {
    return '(${startBehavior.toBracketStr(true)}$start $end${endBehavior.toBracketStr(false)} $attribute)';
  }
}

/// A text attribute with [InsertBehavior] at start and end boundaries.
///
/// Can be converted to an [AttributeSpan] with [toSpan] by providing a range
/// where the attribute should be applied.
@immutable
class AttributeSpanTemplate {
  /// Create an attribute span template.
  const AttributeSpanTemplate(
      this.attribute, this.startBehavior, this.endBehavior);

  /// The attribute spans created from this template will apply.
  ///
  /// See [AttributeSpan.attribute].
  final TextAttribute attribute;

  /// See [AttributeSpan.startBehavior].
  final InsertBehavior startBehavior;

  /// See [AttributeSpan.endBehavior].
  final InsertBehavior endBehavior;

  /// Create a span from this template.
  AttributeSpan toSpan(int start, int end) {
    return AttributeSpan(attribute, start, end, startBehavior, endBehavior);
  }
}

/// A range of the source text with the set of attributes that are applied to it.
//@immutable
class AttributeSegment extends Equatable {
  /// Create an attribute segment.
  const AttributeSegment(this.text, this.attributes);

  /// Create an attribute segment.
  AttributeSegment.from(this.text, Iterable<TextAttribute> attributes)
      : attributes = attributes.toBuiltSet();

  /// Text in this segment.
  final Characters text;

  /// Attributes applied to this segment.
  final BuiltSet<TextAttribute> attributes;

  @override
  String toString() {
    return '$text [${attributes.map((a) => a.runtimeType).join(',')}]';
  }

  @override
  List<Object?> get props => [text, attributes];
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
  ///
  /// All spans are merged and sorted.
  factory SpanList([
    Iterable<AttributeSpan>? spans,
  ]) {
    return spans == null
        ? SpanList._()
        : spans.fold(SpanList._(), (l, s) => l.merge(s));
  }

  SpanList._() : _spans = BuiltList();

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
    var pos = 0;
    return segments.fold<SpanList>(SpanList(), (list, segment) {
      final length = segment.text.length;
      final result = segment.attributes.fold<SpanList>(list, (list, attr) {
        final insertBehavior = getInsertBehavior(attr);
        final span = AttributeSpan(
          attr,
          pos,
          pos + length,
          insertBehavior.start,
          insertBehavior.end,
        );
        return list.merge(span);
      });
      pos += length;
      return result;
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
  /// A segment is a part of the span with one set of attributes
  /// applied to it. A segment maps to a Flutter [TextSpan].
  ///
  /// See [AttributeSegmentsExtensions].buildTextSpans.
  ///
  /// Imagine spans like this:
  ///
  /// ```
  /// ___________
  ///  ____
  ///     _____
  /// ```
  ///
  /// The corresponding segments will be:
  ///
  /// ```
  /// _
  ///  ___
  ///     _
  ///      ____
  ///          __
  /// ```
  Iterable<AttributeSegment> getSegments(Characters t) sync* {
    // We sweep over start and end points of all spans and keep track
    // of what attributes are active, then yield a segment whenever
    // our start point moves.

    final transitions = spans.expand((s) sync* {
      if (s.end > t.length) {
        s = s.copyWith(end: t.length);
      }
      yield _AttributeTransition(
        s.attribute,
        _TransitionType.start,
        s.start,
      );
      yield _AttributeTransition(s.attribute, _TransitionType.end, s.end);
    }).toList()
      ..sort((a, b) => a.index - b.index);

    final textIterator = t.iterator;

    final activeAttribs = <TextAttribute>{};
    var currentIndex = 0;
    for (var i = 0; i < transitions.length; i++) {
      final transition = transitions[i];
      if (transition.index > currentIndex) {
        textIterator.moveNext(transition.index - currentIndex);
        yield AttributeSegment(
          textIterator.currentCharacters,
          activeAttribs.build(),
        );
        currentIndex = transition.index;
      }

      if (transition.type == _TransitionType.start) {
        activeAttribs.add(transition.attribute);
      } else {
        activeAttribs.remove(transition.attribute);
      }
    }

    textIterator.moveNextAll();

    if (textIterator.isNotEmpty) {
      yield AttributeSegment(
        textIterator.currentCharacters,
        BuiltSet(),
      );
    }
  }

  /// If range is not collapsed, returns true if [attribute] is applied to the
  /// full range of text.
  ///
  /// If range is collapsed, returns the result of [willApply] for [attribute].
  bool isApplied(TextAttribute attribute, Range range) {
    return _getSpansIn(range, attribute).any(
      (s) => s.isApplied(range),
    );
  }

  /// Returns true if an insertion at [index] would get [attribute] applied
  /// to it due to a spans [InsertBehavior].
  bool willApply(TextAttribute attribute, int index) {
    return _getSpansIn(Range.collapsed(index), attribute)
        .any((s) => s.willApply(index));
  }

  Iterable<AttributeSpan> _getSpansIn(Range range, TextAttribute attr) =>
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
        toMerge.fold<int>(maxSpanLength, (m, s) => math.min(m, s.start));
    final end = toMerge.fold<int>(-1, (m, s) => math.max(m, s.end));
    final merged = span.copyWith(
      start: start,
      end: end,
    );
    if (merged.isNotCollapsed) {
      return SpanList._sorted(
        _spans
            .whereNot(toMerge.contains)
            .followedBy([merged]).sorted((a, b) => a.start - b.start),
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
  SpanList removeFrom(Range range, TextAttribute attribute) {
    return SpanList(
      _spans.rebuild(
        (b) => b.expand(
          (s) sync* {
            if (s.attribute != attribute || !s.range.overlaps(range)) {
              yield s;
            } else {
              if (s.start < range.start) {
                yield s.copyWith(end: range.start);
              }
              if (range.end < s.end) {
                yield s.copyWith(start: range.end);
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
  SpanList collapse(Range range) {
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

/// Implements [buildTextSpans] for attribute segments.
extension AttributeSegmentsExtensions on Iterable<AttributeSegment> {
  /// Apply the attributes to [text] and return the resulting [TextSpan].
  ///
  /// If [recognizers] is not null, it should contain a mapping
  /// from each text attribute value that wants to apply a gesture to a
  /// corresponding gesture recognizer. The caller is espected to
  /// properly initialize this map and manage the lifetimes of the gesture
  /// recognizers.
  ///
  /// If [recognizers] is null, no gesture recognizers will be put on the
  /// spans.
  TextSpan buildTextSpans({
    required TextStyle style,
    AttributeThemeData? attributeTheme,
    Map<TextAttributeValue, GestureRecognizer>? recognizers,
  }) {
    // TODO multiple gestures
    // TODO WidgetSpan support

    // Flutter issues:
    // - Support WidgetSpan in SelectableText: https://github.com/flutter/flutter/issues/38474
    // - Support WidgetSpan in EditableText: https://github.com/flutter/flutter/issues/30688
    //   I don't think we need gesture recognizers while editing, but this blocks
    //   inline embeds.

    final span = TextSpan(
      style: style,
      children: map((segment) {
        final spanText = segment.text;

        GestureRecognizer? spanRecognizer;

        final theme = attributeTheme ?? AttributeThemeData.empty;

        final attrs =
            segment.attributes.map((attr) => attr.resolve(theme)).toList();

        final style = attrs.fold<TextStyle>(
          const TextStyle(),
          (style, attr) => style.merge(attr.style),
        );

        if (recognizers != null) {
          final spanRecognizers =
              attrs.map((attr) => recognizers[attr]).whereNotNull().toList();
          if (spanRecognizers.length > 1) {
            throw Exception(
                'Tried to have more than 1 gesture recognizers on a single span.');
          } else if (spanRecognizers.length == 1) {
            spanRecognizer = spanRecognizers.first;
          }
        }

        return TextSpan(
          text: spanText.string,
          style: style,
          recognizer: spanRecognizer,
        );
      }).toList(),
    );

    return span;
  }
}
