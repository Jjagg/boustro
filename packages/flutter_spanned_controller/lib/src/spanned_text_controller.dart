import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'attribute_span.dart';
import 'spanned_string.dart';
import 'theme.dart';

/// Result of [SpannedTextEditingController.diffStrings].
class StringDiff extends Equatable {
  /// Create a string diff.
  const StringDiff(this.index, this.deleted, this.inserted)
      : assert(index >= 0, 'Index may not be negative.');

  /// Create a string diff that indicates no changes.
  StringDiff.empty() : this(0, Characters(''), Characters(''));

  /// Index where text was changed.
  final int index;

  /// Deleted text.
  final Characters deleted;

  /// Range in the old text that was deleted.
  Range get deletedRange => Range(index, index + deleted.length);

  /// Inserted text.
  final Characters inserted;

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
  final ExpandRule startBehavior;
  final ExpandRule endBehavior;
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
    ExpandRule startBehavior,
    ExpandRule endBehavior,
  ) {
    if (!selection.isValid || selection.isCollapsed) {
      return;
    }

    final range = _convertRange(selection);
    final span = AttributeSpan(
      attribute,
      range.start,
      range.end,
      startBehavior,
      endBehavior,
    );
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
    return spans.isApplied(attribute, _convertRange(selection));
  }

  /// Toggle an attribute for the current selection.
  ///
  /// For a collapsed selection, if an attribute would normally be applied on
  /// insertion, a call to this method makes it so the attribute is not applied
  /// and vice-versa. I.e. the result of [isApplied] will be
  /// inverted for [attribute] after calling this method. This will only have
  /// an effect if [endBehavior] is set to [ExpandRule.inclusive].
  ///
  /// For a range selection, if the attribute is not applied to the full
  /// selection it will be applied to the full selection. Otherwise the
  /// attribute will be removed from the selection.
  ///
  /// This method uses [setOverride] to temporarily override what attributes
  /// will be applied for collapsed selections.
  bool toggleAttribute(
    TextAttribute attribute,
    ExpandRule startBehavior,
    ExpandRule endBehavior,
  ) {
    final applied = isApplied(attribute);
    if (selection.isCollapsed && endBehavior == ExpandRule.inclusive) {
      final overrideType = applied ? OverrideType.remove : OverrideType.apply;
      setOverride(attribute, overrideType, startBehavior, endBehavior);
    } else {
      if (applied) {
        spans = spans.removeFrom(_convertRange(selection), attribute);
      } else {
        applyAttribute(attribute, startBehavior, endBehavior);
      }
    }

    return !applied;
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
    this.attributeTheme,
    String? text,
    SpanList? spans,
  })  : compositionAttribute = compositionAttribute ??
            TextAttribute.simple(
              debugName: 'composition underline',
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
        _textController = TextEditingController(text: text),
        _spans = spans ?? SpanList();

  /// Create a new spanned text editing controller with the same state as this
  /// one.
  SpannedTextEditingController copy() => SpannedTextEditingController(
      compositionAttribute: compositionAttribute,
      processTextValue: processTextValue,
      text: text,
      spans: spans);

  /// Create a new spanned text editing controller with the same state as this
  /// one, but with the given fields replaced with the new values.
  SpannedTextEditingController copyWith({
    TextAttribute? compositionAttribute,
    ProcessTextValue? processTextValue,
    String? text,
    SpanList? spans,
  }) {
    return SpannedTextEditingController(
      compositionAttribute: compositionAttribute ?? this.compositionAttribute,
      processTextValue: processTextValue ?? this.processTextValue,
      text: text ?? this.text,
      spans: spans ?? this.spans,
    );
  }

  /// The theme for the attributes applied by this span.
  final AttributeThemeData? attributeTheme;

  /// The attribute that's applied to the active composition.
  ///
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
  set spannedString(SpannedString newString) {
    _ignoreSetValue = true;
    value = value.copyWith(text: newString.text.string);
    _ignoreSetValue = false;
    spans = newString.spans;
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
        Range(diff.index, diff.index + diff.inserted.length),
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
    ExpandRule startBehavior,
    ExpandRule endBehavior,
  ) {
    _attributeOverrides
      ..removeWhere((ao) => ao.attribute == attribute)
      ..add(_AttributeOverride(attribute, type, startBehavior, endBehavior));
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({TextStyle? style, required bool withComposing}) {
    if (spans.iter.isEmpty) {
      return _textController.buildTextSpan(
        style: style,
        withComposing: withComposing,
      );
    }

    final segments = !value.isComposingRangeValid ||
            !withComposing ||
            value.composing.isCollapsed
        ? spans.getSegments(text.characters)
        : (spans.merge(
            AttributeSpan(
              compositionAttribute,
              value.composing.start,
              value.composing.end,
              ExpandRule.exclusive,
              ExpandRule.exclusive,
            ),
          )).getSegments(text.characters);

    // We don't pass gesture recognizers here, because we don't
    // want gestures on spans to be handled while editing.
    return segments.buildTextSpans(
      style: style ?? const TextStyle(),
      attributeTheme: attributeTheme,
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

  void _applyOverrides(Range range) {
    // apply overrides
    for (final ao in _attributeOverrides) {
      if (ao.type == OverrideType.apply) {
        final span = AttributeSpan(
          ao.attribute,
          range.start,
          range.end,
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

    final maxInsertion = cursor;
    final maxDeletion =
        math.max(0, oldText.length - newText.length + maxInsertion);

    final oldLength = oldText.characters.length;

    final oldEnd = CharacterRange.at(oldText, maxDeletion, oldText.length)
        .currentCharacters
        .iteratorAtEnd;
    final newEnd = newText.characters.iteratorAtEnd;

    var end = oldLength;
    while (oldEnd.moveBack() &&
        newEnd.moveBack() &&
        oldEnd.current == newEnd.current) {
      end--;
    }

    // TODO clean up this second part

    var start = 0;
    final delta = newText.length - oldText.length;
    final strStartLimit = cursor - math.max<int>(0, delta);
    final startLimit =
        CharacterRange.at(newText, 0, strStartLimit).currentCharacters.length;
    final oldStart = oldText.characters.iterator;
    final newStart = newText.characters.iterator;
    while (start < startLimit &&
        oldStart.moveNext() &&
        newStart.moveNext() &&
        oldStart.current == newStart.current) {
      start++;
    }

    final deleted = oldText.characters.getRange(math.min(start, end), end);
    final inserted =
        newText.characters.getRange(start, math.max(end + delta, start));

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

  /// Normalize [range] and convert from UTF-16 indices to grapheme cluster indices.
  Range _convertRange(TextRange range) {
    if (!range.isNormalized) {
      // ignore: parameter_assignments
      range = TextRange(start: range.end, end: range.start);
    }
    final startChars = CharacterRange.at(text, 0, range.start);
    final start = startChars.currentCharacters.length;
    final rangeChars = CharacterRange.at(text, range.start, range.end);
    final size = rangeChars.currentCharacters.length;
    return Range(start, start + size);
  }
}
