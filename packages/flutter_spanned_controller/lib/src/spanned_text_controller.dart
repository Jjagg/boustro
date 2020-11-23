import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'attribute_span.dart';

/// Result of [SpannedTextController.diffStrings].
@visibleForTesting
class StringDiff extends Equatable {
  const StringDiff(this.index, this.deleted, this.inserted)
      : assert(index >= 0);
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

class _AttributeListener {
  _AttributeListener(this.controller);

  final SpannedTextController controller;
  final List<_AttributeNotifier> notifiers = [];

  ValueListenable<bool> addListener(TextAttribute attribute) {
    final existing =
        notifiers.firstWhereOrNull((e) => e.attribute == attribute);
    if (existing != null) {
      return existing.notifier;
    }

    final current = controller.isApplied(attribute);
    final notifier = ValueNotifier(current);
    notifiers.add(_AttributeNotifier(attribute, notifier));
    return notifier;
  }

  void removeListener(TextAttribute attribute) {
    notifiers.removeWhere((n) => n.attribute == attribute);
  }

  void notify() {
    for (final entry in notifiers) {
      final value = controller.isApplied(entry.attribute);
      entry.notifier.value = value;
    }
  }
}

/// Extensions for [AttributeSpanList].
extension AttributeSpanListExtensions on AttributeSpanList {
  /// Apply the attributes to [text] and return the resulting [TextSpan].
  TextSpan buildTextSpans({required String text, required TextStyle style}) {
    if (!canApplyTo(text)) {
      throw ArgumentError.value(
          text, 'text', 'Spans could not be applied to text.');
    }
    return TextSpan(
      style: style,
      children: segments.map((segment) {
        final spanText = segment.range.textInside(text);
        final spanStyle = segment.attributes
            .fold<TextStyle>(const TextStyle(), (style, attr) => attr.apply(style));
        //print('  > $spanText ${spanStyle.fontWeight == FontWeight.bold ? '(bold)' : ''}');
        return TextSpan(text: spanText, style: spanStyle);
      }).toList(),
    );
  }
}

abstract class SpanController {
  /// Get all applied spans.
  Iterable<AttributeSpan> get spans;

  /// Get the segments for the applied spans.
  Iterable<AttributeSegment> get segments;

  /// Apply a span to the text.
  void addSpan(AttributeSpan span);

  /// Returns true if the [attribute] is applied to the current selection.
  bool isApplied(TextAttribute attribute);

  /// Returns true if the [attribute] would be applied if text was inserted
  /// for the current selection.
  bool willApply(TextAttribute attribute);
}

/// A text editing controller that maintains an [AttributeSpanList]
/// and builds rich text by applying the attributes to its text
/// value.
class SpannedTextController extends TextEditingController
    implements SpanController {
  SpannedTextController({this.compositionAttribute = UnderlineAttribute.value});

  final TextAttribute compositionAttribute;
  final _attributeSpans = AttributeSpanList();
  late final _attributeListener = _AttributeListener(this);

  @override
  Iterable<AttributeSpan> get spans => _attributeSpans.spans;
  @override
  Iterable<AttributeSegment> get segments => _attributeSpans.segments;

  ValueListenable<bool> addAttributeListener(TextAttribute attribute) {
    return _attributeListener.addListener(attribute);
  }

  void removeAttributeListener(TextAttribute attribute) {
    _attributeListener.removeListener(attribute);
  }

  @override
  void addSpan(AttributeSpan span) {
    _attributeSpans.add(span);
    _attributeListener.notify();
  }

  void applyAttribute(TextAttribute attribute, InsertBehavior startBehavior,
      InsertBehavior endBehavior) {
    if (!selection.isValid) {
      return;
    }

    final range = selection.normalize();
    final span = AttributeSpan(attribute, range, startBehavior, endBehavior);
    addSpan(span);
  }

  bool toggleAttribute(
    TextAttribute attribute,
    InsertBehavior startBehavior,
    InsertBehavior endBehavior,
  ) {
    final applied = isApplied(attribute);
    if (applied) {
      if (selection.isCollapsed) {
        if (endBehavior == InsertBehavior.inclusive) {
          applyAttribute(attribute, startBehavior, InsertBehavior.exclusive);
        }
      } else {
        _attributeSpans.removeAllIn(selection, attribute);
        _attributeListener.notify();
      }
    } else {
      if (selection.isCollapsed) {
        if (endBehavior == InsertBehavior.inclusive) {
          applyAttribute(attribute, startBehavior, endBehavior);
        }
      } else {
        applyAttribute(attribute, startBehavior, endBehavior);
      }
    }

    return !applied;
  }

  @override
  bool isApplied(TextAttribute attribute) {
    return _attributeSpans.isApplied(attribute, value.selection);
  }

  @override
  bool willApply(TextAttribute attribute) {
    return _attributeSpans.willApply(attribute, value.selection.baseOffset);
  }

  void _handleValueChange(TextEditingValue newValue) {
    if (newValue.text != text) {
      assert(newValue.selection.isCollapsed);
      final diff =
          diffStrings(text, newValue.text, newValue.selection.baseOffset);
      print(diff);
      print('$newValue');
      _attributeSpans
        ..collapse(diff.deletedRange)
        ..shift(diff.index, diff.inserted.length);
      print('spans: ${_attributeSpans.spans}');
    }
  }

  @override
  set value(TextEditingValue value) {
    // When this is set without a selection, assume the whole
    // text was replaced and put the cursor at the end of the
    // text for diffing purposes.
    final fixedValue = value.selection.isValid
        ? value
        : value.copyWith(
            selection: TextSelection.collapsed(offset: value.text.length),
          );
    _handleValueChange(fixedValue);
    super.value = value;
    _attributeListener.notify();
  }

  /// Builds [TextSpan] from current editing value.
  ///
  /// By default makes text in composing range appear as underlined. Descendants
  /// can override this method to customize appearance of text.
  @override
  TextSpan buildTextSpan({TextStyle? style, required bool withComposing}) {
    if (spans.length == 0) {
      return super.buildTextSpan(style: style, withComposing: withComposing);
    }

    final attribSpans = !value.isComposingRangeValid || !withComposing
        ? _attributeSpans
        : (_attributeSpans.copy()
          ..add(AttributeSpan(
            UnderlineAttribute.value,
            value.composing,
            InsertBehavior.exclusive,
            InsertBehavior.exclusive,
          )));

    return attribSpans.buildTextSpans(
      text: text,
      style: style ?? const TextStyle(),
    );
  }

  /// Diff two strings under the assumption that at most one insertion and one
  /// deletion took place, and both happened at the same index, after which the
  /// cursor was at the given index in the new string.
  @visibleForTesting
  static StringDiff diffStrings(String oldText, String newText, int cursor) {
    assert(cursor >= 0, 'Cursor was negative.');
    assert(cursor <= newText.length, 'Cursor was outside of newText range.');
    final delta = newText.length - oldText.length;
    var limit = math.max(0, cursor - delta);
    var end = oldText.length;
    while (end > limit && oldText[end - 1] == newText[end + delta - 1]) {
      end -= 1;
    }
    var start = 0;
    var startLimit = cursor - math.max(0, delta);
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
}

@immutable
class BoldAttribute extends TextAttribute {
  const BoldAttribute._();

  static const value = BoldAttribute._();

  @override
  TextStyle apply(TextStyle style) {
    return style.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
}

@immutable
class ItalicAttribute extends TextAttribute {
  const ItalicAttribute._();

  static const value = ItalicAttribute._();

  @override
  TextStyle apply(TextStyle style) {
    return style.merge(const TextStyle(fontStyle: FontStyle.italic));
  }
}

@immutable
class UnderlineAttribute extends TextAttribute {
  const UnderlineAttribute._();

  static const value = UnderlineAttribute._();

  @override
  TextStyle apply(TextStyle style) {
    return style.merge(const TextStyle(decoration: TextDecoration.underline));
  }
}
