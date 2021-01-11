import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'attribute_span.dart';
import 'spanned_string.dart';

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

  /// True if the diff indicates the compared strings where identical.
  bool get isEmpty => inserted.isEmpty && deleted.isEmpty;

  /// True if the diff indicates the compared strings where not identical.
  bool get isNotEmpty => inserted.isNotEmpty || deleted.isNotEmpty;

  @override
  String toString() {
    return '''Diff($index, -'$deleted', +'$inserted')''';
  }

  @override
  List<Object?> get props => [index, deleted, inserted];
}

@immutable
class _ToggleStateNotifier<T> {
  const _ToggleStateNotifier(this.value, this.notifier);
  final T value;
  final ValueNotifier<bool> notifier;
}

/// Convenience class that keeps track of whether a [T] is enabled.
class ToggleStateListener<T> {
  /// Create an attribute listener.
  ToggleStateListener();

  final List<_ToggleStateNotifier<T>> _notifiers = [];

  /// Get a value listenable that reports whether [value] is enabled.
  ///
  /// The state of the value will be initialized to [initialValue].
  ValueListenable<bool> listen(T value, {bool initialValue = false}) {
    final existing = _notifiers.firstWhereOrNull((e) => e.value == value);
    if (existing != null) {
      return existing.notifier;
    }

    final current = initialValue;
    final notifier = ValueNotifier(current);
    _notifiers.add(_ToggleStateNotifier<T>(value, notifier));
    return notifier;
  }

  /// Remove the listener for [value] if there is one.
  void removeListener(T value) {
    _notifiers.removeWhere((n) => n.value == value);
  }

  /// Notify this listener that the state of some of its values might have
  /// changed.
  ///
  /// [isEnabled] is used to determine whether a value is enabled.
  void notify(bool Function(T) isEnabled) {
    for (final entry in _notifiers) {
      final value = isEnabled(entry.value);
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

// TODO typedef for generics to not have to define a class here
// https://github.com/dart-lang/language/issues/115

/// Convenience class that keeps track of whether attributes are applied or not.
class AttributeListener extends ToggleStateListener<TextAttribute> {}

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
  );

  final TextAttribute attribute;
  final OverrideType type;

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
  ) {
    if (!selection.isValid || selection.isCollapsed) {
      return;
    }

    final range = _convertRange(selection);
    final span = AttributeSpan(
      attribute,
      range.start,
      range.end,
    );
    spans = spans.merge(span);
  }

  /// Get all attribute spans of type [T] applied to the current selection.
  ///
  /// This method is meant to be used for stateful attributes and does not
  /// currently take overrides into account.
  Iterable<AttributeSpan> getAppliedSpansWithType<T extends TextAttribute>() {
    if (!selection.isValid) {
      return const Iterable<AttributeSpan>.empty();
    }

    return spans.getTypedSpansIn<T>(_convertRange(selection));
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
  /// an effect if the attribute's end rule is set to [ExpandRule.inclusive].
  ///
  /// For a range selection, if the attribute is not applied to the full
  /// selection it will be applied to the full selection. Otherwise the
  /// attribute will be removed from the selection.
  ///
  /// This method uses [setOverride] to temporarily override what attributes
  /// will be applied for collapsed selections.
  bool toggleAttribute(
    TextAttribute attribute,
  ) {
    final applied = isApplied(attribute);
    if (selection.isCollapsed &&
        attribute.expandRules.end == ExpandRule.inclusive) {
      final overrideType = applied ? OverrideType.remove : OverrideType.apply;
      setOverride(attribute, overrideType);
    } else {
      if (applied) {
        spans = spans.removeFrom(_convertRange(selection), attribute);
      } else {
        applyAttribute(attribute);
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

class _DefaultCompositionAttribute extends TextAttribute {
  const _DefaultCompositionAttribute();

  @override
  SpanExpandRules get expandRules => SpanExpandRules.fixed();

  @override
  TextAttributeValue resolve(BuildContext context) => const TextAttributeValue(
        debugName: 'composition underline',
        style: TextStyle(decoration: TextDecoration.underline),
      );
}

const _defaultCompositionAttribute = _DefaultCompositionAttribute();

/// A TextEditingController with rich text capabilities.
class SpannedTextEditingController implements TextEditingController {
  /// Create a new SpannedTextEditingController.
  SpannedTextEditingController({
    required BuildContext buildContext,
    TextAttribute? compositionAttribute,
    this.processTextValue = _defaultProcessTextValue,
    String? text,
    SpanList? spans,
  })  : _buildContext = buildContext,
        compositionAttribute =
            compositionAttribute ?? _defaultCompositionAttribute,
        _textController = TextEditingController(text: text),
        _spans = spans ?? SpanList();

  /// Create a new spanned text editing controller with the same state as this
  /// one.
  SpannedTextEditingController copy() => SpannedTextEditingController(
      buildContext: _buildContext,
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
      buildContext: _buildContext,
      compositionAttribute: compositionAttribute ?? this.compositionAttribute,
      processTextValue: processTextValue ?? this.processTextValue,
      text: text ?? this.text,
      spans: spans ?? this.spans,
    );
  }

  // This is temporary and required because of https://github.com/Jjagg/boustro/issues/10.
  final BuildContext _buildContext;

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

  /// Get the selection as a [Range]. Selection must be valid.
  Range get selectionRange => _convertRange(selection);

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
  ) {
    _attributeOverrides
      ..removeWhere((ao) => ao.attribute == attribute)
      ..add(_AttributeOverride(attribute, type));
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
            ),
          )).getSegments(text.characters);

    // We don't pass gesture recognizers here, because we don't
    // want gestures on spans to be handled while editing.
    return segments.buildTextSpans(
      style: style ?? const TextStyle(),
      context: _buildContext,
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
    if (range.isCollapsed) {
      return;
    }

    for (final ao in _attributeOverrides) {
      if (ao.type == OverrideType.apply) {
        final span = AttributeSpan(
          ao.attribute,
          range.start,
          range.end,
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
    assert(range.isValid, 'Range should be valid.');
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
