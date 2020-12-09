import 'dart:math' as math;
import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'attribute_span.dart';

/// Result of [SpannedTextEditingController.diffStrings].
class StringDiff extends Equatable {
  /// Create a string diff.
  const StringDiff(this.index, this.deleted, this.inserted)
      : assert(index >= 0, 'Index may not be negative.');

  /// Create a string diff that indicates no changes.
  const StringDiff.empty() : this(0, '', '');

  /// Index where text was changed.
  final int index;

  /// Deleted text.
  final String deleted;

  /// Range in the old text that was deleted.
  TextRange get deletedRange =>
      TextRange(start: index, end: index + deleted.length);

  /// Inserted text.
  final String inserted;

  @override
  String toString() {
    return '''Diff($index, -'$deleted', +'$inserted')''';
  }

  @override
  List<Object?> get props => [index, deleted, inserted];
}

@immutable
class _AttributeNotifier {
  const _AttributeNotifier(this.attribute, this.notifier);
  final TextAttribute attribute;
  final ValueNotifier<bool> notifier;
}

/// Convenience class that keeps track of whether attributes are applied or not.
class AttributeListener {
  /// Create an attribute listener.
  AttributeListener();

  final List<_AttributeNotifier> _notifiers = [];

  /// Get a value listenable that reports whether [attribute] is applied.
  ///
  /// The value of the attribute will be initialized to [initialValue].
  ValueListenable<bool> listen(TextAttribute attribute,
      {required bool initialValue}) {
    final existing =
        _notifiers.firstWhereOrNull((e) => e.attribute == attribute);
    if (existing != null) {
      return existing.notifier;
    }

    final current = initialValue;
    final notifier = ValueNotifier(current);
    _notifiers.add(_AttributeNotifier(attribute, notifier));
    return notifier;
  }

  /// Remove the listener for [attribute] if there is one.
  void removeListener(TextAttribute attribute) {
    _notifiers.removeWhere((n) => n.attribute == attribute);
  }

  /// Notify this listener that the state of some of its attributes might have
  /// changed.
  ///
  /// [isApplied] is used to determine whether an attribute is applied.
  void notify(bool Function(TextAttribute) isApplied) {
    for (final entry in _notifiers) {
      final value = isApplied(entry.attribute);
      entry.notifier.value = value;
    }
  }

  /// Dispose all listeners.
  void dispose() {
    for (final entry in _notifiers) {
      entry.notifier.dispose();
    }
  }
}

/// Implements [buildTextSpans] for attribute segments.
extension AttributeSegmentsExtensions on Iterable<AttributeSegment> {
  /// Apply the attributes to [text] and return the resulting [TextSpan].
  ///
  /// If [recognizers] is not null, it should contain a mapping
  /// from each text attribute that wants to apply a gesture to a
  /// corresponding gesture recognizer. The caller is espected to
  /// properly initialize this map and manage the lifetimes of the gesture
  /// recognizers.
  ///
  /// If [recognizers] is null no gesture recognizers will be put on the
  /// spans.
  TextSpan buildTextSpans({
    required String text,
    required TextStyle style,
    Map<TextAttribute, GestureRecognizer>? recognizers,
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
        final spanText = segment.range.textInside(text);

        GestureRecognizer? spanRecognizer;

        final style = segment.attributes.fold<TextStyle>(
          const TextStyle(),
          (style, attr) => style.merge(attr.style),
        );

        if (recognizers != null) {
          final spanRecognizers = segment.attributes
              .map((attr) => recognizers[attr])
              .whereNotNull()
              .toList();
          if (spanRecognizers.length > 1) {
            throw Exception(
                'Tried to have more than 1 gesture recognizers on a single span.');
          } else if (spanRecognizers.length == 1) {
            spanRecognizer = spanRecognizers.first;
          }
        }

        return TextSpan(
          text: spanText,
          style: style,
          recognizer: spanRecognizer,
        );
      }).toList(),
    );

    return span;
  }
}

/// Passed to [SpannedTextEditingController.setOverride] to indicate if
/// a [TextAttribute] should be applied or removed.
enum OverrideType {
  /// The attribute will be applied on the next insertion.
  apply,

  /// The attribute will be removed on the next insertion.
  remove,
}

class _AttributeOverride {
  const _AttributeOverride(
    this.attribute,
    this.type,
    this.startBehavior,
    this.endBehavior,
  );

  final TextAttribute attribute;
  final OverrideType type;
  final InsertBehavior startBehavior;
  final InsertBehavior endBehavior;
  @override
  String toString() {
    return '$attribute -> $type';
  }
}

/// High-level convenience methods for SpannedTextEditingController.
extension SpannedTextEditingControllerExtension
    on SpannedTextEditingController {
  /// Apply an attribute to the current selection.
  void applyAttribute(
    TextAttribute attribute,
    InsertBehavior startBehavior,
    InsertBehavior endBehavior,
  ) {
    if (!selection.isValid || selection.isCollapsed) {
      return;
    }

    final range = selection.normalize();
    final span = AttributeSpan(attribute, range, startBehavior, endBehavior);
    spans = spans.merge(span);
  }

  /// Determines if [attribute] is applied to the full selection (for a ranged
  /// selection) or would be applied on insertion (for a collapsed selection).
  bool isApplied(TextAttribute attribute) {
    if (!selection.isValid) {
      return false;
    }
    if (_attributeOverrides.any(
        (ov) => ov.attribute == attribute && ov.type == OverrideType.apply)) {
      return true;
    }
    if (_attributeOverrides.any(
        (ov) => ov.attribute == attribute && ov.type == OverrideType.remove)) {
      return false;
    }
    return spans.isApplied(attribute, selection.normalize());
  }

  /// Toggle an attribute for the current selection.
  ///
  /// For a collapsed selection, if an attribute would normally be applied on
  /// insertion, a call to this method makes it so the attribute is not applied
  /// and vice-versa. I.e. the result of [isApplied] will be
  /// inverted for [attribute] after calling this method. This will only have
  /// an effect if [endBehavior] is set to [InsertBehavior.inclusive].
  ///
  /// For a range selection, if the attribute is not applied to the full
  /// selection it will be applied to the full selection. Otherwise the
  /// attribute will be removed from the selection.
  ///
  /// This method uses [setOverride] to temporarily override what attributes
  /// will be applied for collapsed selections.
  bool toggleAttribute(
    TextAttribute attribute,
    InsertBehavior startBehavior,
    InsertBehavior endBehavior,
  ) {
    final applied = isApplied(attribute);
    if (selection.isCollapsed && endBehavior == InsertBehavior.inclusive) {
      final overrideType = applied ? OverrideType.remove : OverrideType.apply;
      setOverride(attribute, overrideType, startBehavior, endBehavior);
    } else {
      if (applied) {
        spans = spans.removeFrom(selection, attribute);
      } else {
        applyAttribute(attribute, startBehavior, endBehavior);
      }
    }

    return !applied;
  }
}

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

  /// Insert text into this spanned text. The spans are shifted to accomodate
  /// for the insertion.
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

  /// Delete a part of this spanned text. The spans are shifted and deleted to
  /// accomodate for the deletion.
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
    return this
        .collapse(after: diff.index, before: diff.index + diff.deleted.length)
        .insert(diff.index, diff.inserted);
  }

  /// Apply the attributes to [text] and return the resulting [TextSpan].
  ///
  /// See [AttributeSegmentsExtensions].
  TextSpan buildTextSpans(
      {required TextStyle style,
      Map<TextAttribute, GestureRecognizer>? recognizers}) {
    final segments = spans.getSegments(text.length);
    return segments.buildTextSpans(
        text: text, style: style, recognizers: recognizers);
  }

  @override
  String toString() {
    return '$text <$spans>';
  }
}

/// Used by [SpannedTextEditingController] to process
/// [SpannedTextEditingController.value] whenever it changes.
typedef ProcessTextValue = TextEditingValue Function(
  SpannedTextEditingController,
  TextEditingValue,
);

/// A TextEditingController with rich text capabilities.
class SpannedTextEditingController implements TextEditingController {
  /// Create a new SpannedTextEditingController.
  SpannedTextEditingController({
    TextAttribute? compositionAttribute,
    this.processTextValue = _defaultProcessTextValue,
    String? text,
    Iterable<AttributeSpan>? spans,
  })  : compositionAttribute = compositionAttribute ??
            const TextAttribute(
              debugName: 'composition underline',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
        _textController = TextEditingController(text: text),
        _spans = SpanList(spans);

  /// Create a new spanned text editing controller with the same state as this
  /// one.
  SpannedTextEditingController copy() => SpannedTextEditingController(
      compositionAttribute: compositionAttribute,
      processTextValue: processTextValue,
      text: text,
      spans: spans.spans);

  /// Create a new spanned text editing controller with the same state as this
  /// one, but with the given fields replaced with the new values.
  SpannedTextEditingController copyWith({
    TextAttribute? compositionAttribute,
    ProcessTextValue? processTextValue,
    String? text,
    Iterable<AttributeSpan>? spans,
  }) {
    return SpannedTextEditingController(
        compositionAttribute: compositionAttribute ?? this.compositionAttribute,
        processTextValue: processTextValue ?? this.processTextValue,
        text: text ?? this.text,
        spans: spans ?? this.spans.spans);
  }

  /// The attribute that's applied to the active composition.
  /// By default this adds an underline decoration.
  final TextAttribute compositionAttribute;

  /// Used to process [value] whenever it changes.
  final ProcessTextValue processTextValue;

  final TextEditingController _textController;

  SpanList _spans;

  /// Get the list of spans that determine the formatting of the text.
  SpanList get spans => _spans;
  set spans(SpanList spans) {
    if (_spans != spans) {
      _spans = spans;
      notifyListeners();
    }
  }

  /// Get the rich text contents managed by this controller.
  SpannedString get spannedString => SpannedString(text, spans);

  /// Set the rich text contents managed by this controller.
  set spannedString(SpannedString newText) {
    _ignoreSetValue = true;
    value = value.copyWith(text: newText.text);
    _ignoreSetValue = false;
    spans = newText.spans;
  }

  bool _ignoreSetValue = false;
  final List<_AttributeOverride> _attributeOverrides = [];

  @override
  TextSelection get selection => _textController.selection;

  @override
  set selection(TextSelection newSelection) {
    if (!isSelectionWithinTextBounds(newSelection)) {
      throw FlutterError('invalid text selection: $newSelection');
    }
    final newComposing = newSelection.isCollapsed &&
            _isSelectionWithinComposingRange(newSelection)
        ? value.composing
        : TextRange.empty;
    value = value.copyWith(selection: newSelection, composing: newComposing);
  }

  @override
  String get text => _textController.text;

  @override
  set text(String? newText) {
    value = value.copyWith(
      text: newText,
      selection: const TextSelection.collapsed(offset: -1),
      composing: TextRange.empty,
    );
  }

  @override
  TextEditingValue get value => _textController.value;

  @override
  set value(TextEditingValue value) {
    if (_ignoreSetValue) {
      _textController.value = value;
    } else {
      final pValue = processTextValue(this, value);
      // We set the cursor at the end of the inserted text for diffing purposes
      // when it is invalid.
      final cursor = pValue.selection.isValid
          ? pValue.selection.baseOffset
          : pValue.text.length;
      final diff = diffStrings(text, pValue.text, cursor);
      spans = spans
          .collapse(diff.deletedRange)
          .shift(diff.index, diff.inserted.length);
      _applyOverrides(
        TextRange(start: diff.index, end: diff.index + diff.inserted.length),
      );

      if (pValue.selection != _textController.selection ||
          pValue.text != _textController.text) {
        _attributeOverrides.clear();
      }

      _textController.value = pValue;
    }
  }

  /// Override whether or not an attribute will be applied on the next
  /// insertion.
  ///
  /// Overrides are cleared whenever [selection] or [text] changes.
  void setOverride(
    TextAttribute attribute,
    OverrideType type,
    InsertBehavior startBehavior,
    InsertBehavior endBehavior,
  ) {
    _attributeOverrides
      ..removeWhere((ao) => ao.attribute == attribute)
      ..add(_AttributeOverride(attribute, type, startBehavior, endBehavior));
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({TextStyle? style, required bool withComposing}) {
    if (spans.spans.isEmpty) {
      return _textController.buildTextSpan(
        style: style,
        withComposing: withComposing,
      );
    }

    final segments = !value.isComposingRangeValid ||
            !withComposing ||
            value.composing.isCollapsed
        ? spans.getSegments(text.length)
        : (spans.merge(AttributeSpan(
            compositionAttribute,
            value.composing,
            InsertBehavior.exclusive,
            InsertBehavior.exclusive,
          ))).getSegments(text.length);

    // We don't pass gesture recognizers here, because we don't
    // want gestures on spans to be handled while editing.
    return segments.buildTextSpans(
      text: text,
      style: style ?? const TextStyle(),
    );
  }

  @override
  void clear() {
    _ignoreSetValue = true;
    _textController.clear();
    _spans = SpanList();
    _ignoreSetValue = false;
  }

  @override
  void dispose() {
    _textController.dispose();
  }

  @override
  void clearComposing() => _textController.clearComposing();

  @override
  bool isSelectionWithinTextBounds(TextSelection selection) =>
      _textController.isSelectionWithinTextBounds(selection);

  @override
  void addListener(void Function() listener) =>
      _textController.addListener(listener);

  @override
  bool get hasListeners => _textController.hasListeners;

  @override
  void notifyListeners() => _textController.notifyListeners();

  @override
  void removeListener(void Function() listener) =>
      _textController.removeListener(listener);

  void _applyOverrides(TextRange range) {
    // apply overrides
    for (final ao in _attributeOverrides) {
      if (ao.type == OverrideType.apply) {
        final span = AttributeSpan(
          ao.attribute,
          range,
          ao.startBehavior,
          ao.endBehavior,
        );
        spans = spans.merge(span);
      } else {
        spans = spans.removeFrom(range, ao.attribute);
      }
    }
  }

  /// Check that the [selection] is inside of the composing range.
  bool _isSelectionWithinComposingRange(TextSelection selection) {
    return selection.start >= value.composing.start &&
        selection.end <= value.composing.end;
  }

  static TextEditingValue _defaultProcessTextValue(
          SpannedTextEditingController _, TextEditingValue value) =>
      value;

  /// Diff two strings under the assumption that at most one insertion and one
  /// deletion took place, and both happened at the same index, after which the
  /// cursor was at index [cursor] in the new string.
  static StringDiff diffStrings(String oldText, String newText, int cursor) {
    assert(cursor >= 0, 'Cursor was negative.');
    assert(cursor <= newText.length, 'Cursor was outside of newText range.');
    final delta = newText.length - oldText.length;
    final limit = math.max(0, cursor - delta);
    var end = oldText.length;
    while (end > limit && oldText[end - 1] == newText[end + delta - 1]) {
      end -= 1;
    }
    var start = 0;
    final startLimit = cursor - math.max(0, delta);
    while (start < startLimit && oldText[start] == newText[start]) {
      start += 1;
    }
    final deleted = (start < end) ? oldText.substring(start, end) : '';
    final inserted = newText.substring(start, end + delta);

    assert(start + inserted.length == cursor,
        'start + inserted.length != cursor. Probably bad input.');

    return StringDiff(
      start,
      deleted,
      inserted,
    );
  }

  @override
  String toString() {
    return _textController.toString();
  }
}
