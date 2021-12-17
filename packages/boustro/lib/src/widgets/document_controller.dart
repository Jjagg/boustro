import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../document.dart';
import '../spans/attribute_span.dart';
import '../spans/spanned_string.dart';
import '../spans/spanned_text_controller.dart';
import 'editor.dart';

/// Holds state for a paragraph of a document.
@immutable
abstract class ParagraphState {
  /// Create a paragraph.
  const ParagraphState({required FocusNode focusNode}) : _focusNode = focusNode;

  final FocusNode _focusNode;

  /// Manages focus for this paragraph.
  FocusNode get focusNode => _focusNode;

  /// Discards resources used by this object.
  @mustCallSuper
  void dispose() {
    focusNode.dispose();
  }

  /// Execute [line] if this is a [LineState] and [embed] if this is an
  /// [EmbedState].
  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  });
}

/// Holds focus node and state for a line of text.
///
/// This is the editable variant of [LineParagraph].
@immutable
class LineState extends ParagraphState {
  /// Create a text line.
  LineState({
    required SpannedTextEditingController controller,
    required FocusNode focusNode,
    Iterable<LineModifier>? modifiers,
  }) : this.built(
          controller: controller,
          focusNode: focusNode,
          modifierController: LineModifierController(modifiers),
        );

  /// Create a text line, directly providing the values for its fields.
  const LineState.built({
    required this.controller,
    required FocusNode focusNode,
    required this.modifierController,
  }) : super(focusNode: focusNode);

  /// The [TextEditingController] that manages the text
  /// and markup of this line.
  final SpannedTextEditingController controller;

  /// Manages modifiers that can affect how this line is displayed.
  ///
  /// Modifiers are applied in order, wrapping each other. E.g. if modifiers is
  /// equal to `[a, b]`, then they will be applied as `b(a(line))`.
  final LineModifierController modifierController;

  /// Get the current list of modifiers stored by [modifierController].
  BuiltList<LineModifier> get modifiers => modifierController.modifiers;

  @override
  void dispose() {
    controller.dispose();
    modifierController.dispose();
    super.dispose();
  }

  @override
  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  }) =>
      line(this);
}

/// Manages a list of [LineModifier] and notifies whenever the list changes.
class LineModifierController extends ValueNotifier<BuiltList<LineModifier>> {
  /// Create a line modifier controller.
  LineModifierController([Iterable<LineModifier>? modifiers])
      : super(BuiltList.from(modifiers ?? const <LineModifier>[]));

  /// Get the modifier list.
  BuiltList<LineModifier> get modifiers => value;

  /// Mutate the list of modifiers.
  void update(dynamic Function(ListBuilder<LineModifier>) updates) {
    value = modifiers.rebuild(updates);
  }
}

/// Holds [FocusNode] and content for an embed.
@immutable
class EmbedState extends ParagraphState {
  /// Create an embed.
  const EmbedState({
    required FocusNode focusNode,
    required this.controller,
  }) : super(focusNode: focusNode);

  /// Editor for the embed.
  final ParagraphEmbedController controller;

  @override
  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  }) =>
      embed(this);

  /// Create an editor for this embed state.
  Widget createEditor(BuildContext context) {
    return controller.createEditor(context, focusNode);
  }
}

/// Event data for [DocumentController.onLineValueChanged].
class LineValueChangedEvent {
  /// Create a LineValueChangedEvent.
  const LineValueChangedEvent(this.state);

  /// State of the line that had its value changed.
  final LineState state;
}

/// Event data for [DocumentController.onParagraphAdded] and
/// [DocumentController.onParagraphRemoved].
@immutable
class ParagraphEvent {
  /// Create a ParagraphEvent.
  const ParagraphEvent(this.state);

  /// State of the paragraph.
  final ParagraphState state;
}

@immutable
class _ToggleStateNotifier<T> {
  const _ToggleStateNotifier(this.value, this.notifier);
  final T value;
  final ValueNotifier<bool> notifier;
}

/// Convenience class that keeps track of whether a [T] is enabled.
class _ToggleStateListener<T> {
  /// Create a toggle state listener.
  _ToggleStateListener();

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

/// Manages the contents of a [DocumentEditor].
///
/// Keeps track of the state of its paragraphs and editor:
///
/// * SpannedTextEditingController for text
/// * FocusNode for both text and embeds
/// * ScrollController for the scroll view of the editor
///
/// It also handles creation and deletion of lines based on user actions and
/// ensures a consistent state when editing its controllers or paragraphs.
///
/// * Backspace at the start of a line will try to merge it with the previous line.
/// * Delete at the end of a line tries to merge the next line into the current one.
/// * newline (\n) cause the line to split; no line may ever contain a newline character.
/// * There is always a text line at the start and one at the end (before and after any embed paragraphs).
class DocumentController extends ValueNotifier<BuiltList<ParagraphState>> {
  /// Create a document controller.
  DocumentController({
    FocusScopeNode? focusNode,
    Iterable<Paragraph>? paragraphs,
  })  : focusNode = focusNode ?? FocusScopeNode(),
        super(BuiltList()) {
    if (focusNode == null) {
      _ownedFocusNode = focusNode;
    }
    if (paragraphs == null) {
      appendLine();
    } else {
      for (final p in paragraphs) {
        p.match(
          line: appendLine,
          embed: appendEmbed,
        );
      }
    }
  }

  FocusScopeNode? _ownedFocusNode;
  ParagraphState? _focusedParagraph;

  /// The focus scope node for the controller.
  final FocusScopeNode focusNode;

  // EVENTS

  final StreamController<LineValueChangedEvent> _lineValueChangedController =
      StreamController.broadcast();

  /// Stream of events fired when a text line's [TextEditingValue] changes.
  Stream<LineValueChangedEvent> get onLineValueChanged =>
      _lineValueChangedController.stream;

  final StreamController<ParagraphEvent> _paragraphAddedController =
      StreamController.broadcast();

  /// Stream of events fired when a paragraph is added.
  Stream<ParagraphEvent> get onParagraphAdded =>
      _paragraphAddedController.stream;

  final StreamController<ParagraphEvent> _paragraphRemovedController =
      StreamController.broadcast();

  /// Stream of events fired when a paragraph is removed.
  Stream<ParagraphEvent> get onParagraphRemoved =>
      _paragraphRemovedController.stream;

  @protected
  @override
  BuiltList<ParagraphState> get value => super.value;

  /// Get the paragraphs in this docuent.
  ///
  /// Alias for [value].
  BuiltList<ParagraphState> get paragraphs => value;

  /// Sets the paragraphs in this document.
  ///
  /// Alias for [value].
  set paragraphs(BuiltList<ParagraphState> newValue) => value = newValue;

  void _rebuild(dynamic Function(ListBuilder<ParagraphState>) updates) {
    value = value.rebuild(updates);
  }

  /// Get the index of the focused paragraph or null if no paragraph has focus.
  int? get focusedParagraphIndex {
    final p = _focusedParagraph;
    return p == null ? null : paragraphs.indexOf(p);
  }

  /// Get the currently focused paragraph, if any.
  ParagraphState? get focusedParagraph => _focusedParagraph;

  /// Get the currently focused line. If there is no focused paragraph or the
  /// [focusedParagraph] is not a [LineState] this returns null.
  LineState? get focusedLine =>
      focusedParagraph is LineState ? focusedParagraph as LineState? : null;

  /// This function is called anytime the [TextEditingValue] of a controller
  /// changes.
  ///
  /// It's responsible for:
  /// - Detecting backspace at the start of a line or delete at the end to join
  ///   lines.
  /// - Detecting newline insertions to split lines.
  /// - Correcting the selection so it is always within the start/end line
  ///   markers.
  TextEditingValue _processTextValue(
    SpannedTextEditingController controller,
    TextEditingValue newValue,
  ) {
    // Find the index of the line for merging or splitting.
    final lineIndex = paragraphs.indexWhere(
      (ctrl) => ctrl is LineState && identical(ctrl.controller, controller),
    );
    assert(lineIndex >= 0, 'processTextValue called with missing controller.');

    final cursor = newValue.selection.isValid
        ? newValue.selection.baseOffset
        : newValue.text.length;

    // Diff the strings to detect marker deletion or newline insertion.
    final diff = SpannedTextEditingController.diffStrings(
      controller.text,
      newValue.text,
      cursor,
    );

    if (diff.deletedRange.contains(const Range(0, 1))) {
      if (_tryMergeNext(lineIndex - 1)) {
        return TextEditingValue.empty;
      } else {
        newValue = newValue.copyWith(text: _lineMarker + newValue.text);
      }
    }

    if (diff.deletedRange
        .contains(Range(controller.text.length - 1, controller.text.length))) {
      final index = paragraphs.indexWhere(
        (ctrl) => ctrl is LineState && identical(ctrl.controller, controller),
      );
      if (_tryMergeNext(index)) {
        return TextEditingValue.empty;
      } else {
        newValue = newValue.copyWith(text: newValue.text + _lineMarker);
      }
    }

    newValue = _ensureValidSelection(newValue);

    if (!newValue.text.contains('\n')) {
      return newValue;
    }

    final line = controller.spannedString.applyDiff(diff);
    return _handleNewlines(lineIndex, line, newValue);
  }

  /// Split the given line on each newline character.
  TextEditingValue _handleNewlines(
    int lineIndex,
    SpannedString string,
    TextEditingValue newValue,
  ) {
    // Remove trailing line marker.
    string = string.collapse(start: string.length - 1, end: string.length);

    final line = paragraphs[lineIndex] as LineState;

    // We loop through the string from the end to split of the last line, until
    // we have no more newline characters.

    CharacterRange? newlineRange;
    LineState? toFocus;
    while ((newlineRange = string.text.findLast('\n'.characters)) != null) {
      newlineRange!;

      final remainingLength = newlineRange.charactersBefore.length;
      final indexAfterNewline = remainingLength + 1;
      final nextLine = string.collapse(end: indexAfterNewline);
      insertLine(
        lineIndex + 1,
        LineParagraph.built(
          text: nextLine.text,
          spans: nextLine.spans,
          modifiers: line.modifiers,
        ),
      );

      // Prune off the handled line and the newline character preceding it.
      string = string.collapse(start: remainingLength);

      // Focus the final line after the operation.
      toFocus ??= paragraphs[lineIndex + 1] as LineState;
    }

    if (toFocus != null) {
      toFocus.focusNode.requestFocus();
      toFocus.controller.selection = toFocus.controller.selection.copyWith(
        baseOffset: 1,
        extentOffset: 1,
      );
    }

    return _ensureValidSelection(
      TextEditingValue(
        // Re-add trailing line marker.
        text: string.text.toString() + _lineMarker,
        selection: newValue.selection.copyWith(
          baseOffset: string.length,
          extentOffset: string.length,
        ),
      ),
    );
  }

  /// Get the contents of this controller represented as a document.
  Document toDocument() {
    final paragraphs = this
        .paragraphs
        .map((p) {
          return p.match<Paragraph?>(
            line: (l) {
              // Trim off the marker characters.
              final spans = l.controller.spans.collapse(const Range(0, 1));
              final text = l.controller.text
                  .substring(1, l.controller.text.length - 1)
                  .characters;

              return LineParagraph.built(
                spans: spans,
                text: text,
                modifiers: l.modifierController.modifiers,
              );
            },
            embed: (e) => e.controller.toEmbed(),
          );
        })
        .whereNotNull()
        .toBuiltList();
    return Document.built(paragraphs);
  }

  /// Add a line after all existing paragraphs.
  LineState appendLine([LineParagraph? line]) {
    return insertLine(paragraphs.length, line);
  }

  /// Insert a line at [index].
  LineState insertLine(int index, [LineParagraph? line]) {
    final spanController = SpannedTextEditingController(
      processTextValue: _processTextValue,
      text: _addLineMarkers(line?.text.string),
      spans: line?.spans.shift(0, 1),
      hasMarkerCharacters: true,
    );

    final focusNode = FocusNode();

    final newLine = LineState(
      controller: spanController,
      focusNode: focusNode,
      modifiers: line?.modifiers.asList(),
    );

    spanController.addListener(() {
      _lineValueChangedController.add(LineValueChangedEvent(newLine));

      if (!focusNode.hasPrimaryFocus) {
        return;
      }

      _attributeListener.notify(
        spanController.isApplied,
      );
      _attributeTypeListener.notify((type) {
        return spanController.getAppliedSpansWithUnsafeType(type).isNotEmpty;
      });
    });

    newLine.modifierController.addListener(() {
      if (newLine.focusNode.hasPrimaryFocus) {
        _modifierListener.notify(newLine.modifiers.contains);
      }
    });

    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        _focusedParagraph = newLine;
        _modifierListener.notify(newLine.modifiers.contains);
        _attributeListener.notify(
          spanController.isApplied,
        );
        _attributeTypeListener.notify((type) {
          return spanController.getAppliedSpansWithUnsafeType(type).isNotEmpty;
        });
      } else {
        if (_focusedParagraph == newLine) {
          _focusedParagraph = null;
          _modifierListener.notify((_) => false);
          _attributeListener.notify((_) => false);
          _attributeTypeListener.notify((_) => false);
        }
      }
    });

    _rebuild((r) => r.insert(index, newLine));
    _paragraphAddedController.add(ParagraphEvent(newLine));
    return newLine;
  }

  /// Apply a text attribute to the currently focused line, if there is one.
  void setLineStyle(TextAttribute attribute) {
    final line = focusedLine;
    if (line != null) {
      setLineStyleOf(line, attribute);
    }
  }

  /// Apply a text attribute to the line at the given index, if the index is
  /// valid and points to a [LineState].
  void setLineStyleAt(int index, TextAttribute attribute) {
    if (index >= 0 && index < paragraphs.length) {
      final paragraph = paragraphs[index];
      if (paragraph is LineState) {
        setLineStyleOf(paragraph, attribute);
      }
    }
  }

  /// Apply a text attribute to the given line. Typically used with attributes
  /// with [SpanExpandRules.fixed].
  void setLineStyleOf(LineState line, TextAttribute attribute) {
    final ctrl = line.controller;
    final span = AttributeSpan(
      attribute,
      0,
      maxSpanLength,
    );
    ctrl.spans = ctrl.spans.merge(span);
  }

  /// Remove a text attribute from the currently focused line, if there is one.
  void unsetLineStyle(TextAttribute attribute) {
    final line = focusedLine;
    if (line != null) {
      unsetLineStyleOf(line, attribute);
    }
  }

  /// Remove a text attribute from the line at the given index, if the index is
  /// valid and points to a [LineState].
  void unsetLineStyleAt(int index, TextAttribute attribute) {
    if (index >= 0 && index < paragraphs.length) {
      final paragraph = paragraphs[index];
      if (paragraph is LineState) {
        setLineStyleOf(paragraph, attribute);
      }
    }
  }

  /// Remove a text attribute from the currently focused line, if there is one.
  void unsetLineStyleOf(LineState line, TextAttribute attribute) {
    final line = focusedLine;
    if (line != null) {
      final ctrl = line.controller;
      ctrl.spans = ctrl.spans.removeAll(attribute);
    }
  }

  /// Toggle an attribute for the current line.
  ///
  /// Calls either [setLineStyle] or [unsetLineStyle] depending
  /// on whether the attribute is already applied.
  void toggleLineStyle(TextAttribute attribute) {
    final line = focusedLine;
    if (line != null) {
      if (line.controller.isApplied(attribute)) {
        unsetLineStyleOf(line, attribute);
      } else {
        setLineStyleOf(line, attribute);
      }
    }
  }

  /// Toggles a line modifier for the focused line.
  void toggleLineModifier(LineModifier modifier) {
    final focusIndex = focusedParagraphIndex;
    if (focusIndex != null && paragraphs[focusIndex] is LineState) {
      final line = paragraphs[focusIndex] as LineState;
      final hasModifier = line.modifiers.contains(modifier);
      if (hasModifier) {
        line.modifierController.update((r) => r.remove(modifier));
      } else {
        line.modifierController.update((r) => r.insert(0, modifier));
      }
    }
  }

  /// Remove the focused paragraph.
  ///
  /// Does nothing if [focusedParagraph] is null.
  void removeCurrentParagraph() {
    final index = focusedParagraphIndex;
    if (index != null) {
      removeParagraphAt(index);
    }
  }

  /// Remove the paragraph at [index].
  void removeParagraphAt(int index) {
    if (index < 0 || index >= paragraphs.length) {
      return;
    }

    _rebuild((r) {
      final state = r.removeAt(index);

      _paragraphRemovedController.add(ParagraphEvent(state));

      // We defer disposal until after the next build, because the
      // EditableText will be removed from the tree and disposed, and it
      // will access our controller, causing issues if we dispose it here
      // immediately.
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        state.dispose();
      });
    });
  }

  /// Add an embed after all existing paragraphs.
  EmbedState appendEmbed(ParagraphEmbed embed) {
    return insertEmbed(paragraphs.length, embed);
  }

  /// Insert an embed at the current index.
  EmbedState? insertEmbedAtCurrent(
    ParagraphEmbed embed, {
    bool deleteLineIfEmpty = true,
  }) {
    // We replace the current line if it's empty.
    var index = focusedParagraphIndex;
    if (index == null) {
      return null;
    }
    final p = paragraphs[index];
    if (p is LineState && p.controller.text.isEmpty) {
      removeParagraphAt(index);
    } else {
      index += 1;
    }
    return insertEmbed(index + 1, embed, deleteLineIfEmpty: deleteLineIfEmpty);
  }

  /// Insert an embed at [index].
  EmbedState insertEmbed(
    int index,
    ParagraphEmbed embed, {
    bool deleteLineIfEmpty = true,
  }) {
    // Delete the line if it's an empty text line.
    if (deleteLineIfEmpty && index > 0) {
      final p = paragraphs[index - 1];
      if (p is LineState && p.controller.text.isEmpty) {
        removeParagraphAt(index - 1);
        index = index - 1;
      }
    }

    final focus = FocusNode();

    final state = EmbedState(
      focusNode: focus,
      controller: embed.createController(),
    );

    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        _focusedParagraph = state;
      } else if (_focusedParagraph == state) {
        _focusedParagraph = null;
      }
    });

    if (index == paragraphs.length) {
      appendLine();
    }
    if (index == 0) {
      insertLine(0);
    }
    _rebuild((r) {
      r.insert(index == 0 ? 1 : index, state);
    });

    _paragraphAddedController.add(ParagraphEvent(state));
    return state;
  }

  bool _tryMergeNext(int index) {
    if (index < 0 || index + 1 >= paragraphs.length) {
      return false;
    }
    if (paragraphs[index] is! LineState ||
        paragraphs[index + 1] is! LineState) {
      return false;
    }
    final c1 = paragraphs[index] as LineState;
    final c2 = paragraphs[index + 1] as LineState;

    // Remove the line markers.
    final s1 = c1.controller.spannedString
        .collapse(start: c1.controller.spannedString.length - 1);
    final s2 = c2.controller.spannedString.collapse(end: 1);

    final insertionIndex = s1.length;
    final concat = s1.concat(s2);

    c1.controller.spannedString = concat;
    removeParagraphAt(index + 1);
    c1.focusNode.requestFocus();

    // Put the cursor at the insertion point
    c1.controller.selection = c1.controller.selection.copyWith(
      baseOffset: insertionIndex,
      extentOffset: insertionIndex,
    );

    return true;
  }

  final _ToggleStateListener<TextAttribute> _attributeListener =
      _ToggleStateListener<TextAttribute>();
  final _ToggleStateListener<Type> _attributeTypeListener =
      _ToggleStateListener<Type>();
  final _ToggleStateListener<LineModifier> _modifierListener =
      _ToggleStateListener<LineModifier>();

  /// Get a [ValueListenable] that indicates if [attribute]
  /// is applied for the current selection.
  ///
  /// Values will always be false if there is no valid selection.
  ValueListenable<bool> getAttributeListener(TextAttribute attribute) {
    return _attributeListener.listen(attribute);
  }

  /// Get a [ValueListenable] that indicates if an attribute of type [T]
  /// is applied for the current selection.
  ///
  /// Values will always be false if there is no valid selection.
  ValueListenable<bool> getAttributeTypeListener<T extends TextAttribute>() {
    return _attributeTypeListener.listen(T);
  }

  /// Get a [ValueListenable] that indicates if [modifier]
  /// is applied for the current line.
  ///
  /// Values will always be false if no line is focused.
  ValueListenable<bool> getModifierListener(LineModifier modifier) {
    return _modifierListener.listen(modifier);
  }

  @override
  void dispose() {
    _lineValueChangedController.close();
    _paragraphAddedController.close();
    _paragraphRemovedController.close();

    _attributeListener.dispose();
    _attributeTypeListener.dispose();
    _modifierListener.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  static const _lineMarker = ' ';

  bool _hasStartLineMarker(TextEditingValue value) {
    final text = value.text;

    if (text.isEmpty) {
      return false;
    }

    if (text[0] != _lineMarker) {
      return false;
    }

    if (text.length == 1 &&
        value.selection.isCollapsed &&
        value.selection.baseOffset == 0) {
      return false;
    }

    return true;
  }

  bool _hasEndLineMarker(TextEditingValue value) {
    final text = value.text;

    if (text.isEmpty) {
      return false;
    }

    if (text[text.length - 1] != _lineMarker) {
      return false;
    }

    if (text.length == 1 &&
        value.selection.isCollapsed &&
        value.selection.baseOffset == 1) {
      return false;
    }

    return true;
  }

  TextEditingValue _ensureValidSelection(TextEditingValue value) {
    assert(_hasStartLineMarker(value) && _hasEndLineMarker(value),
        'Text value did not have start and end line markers.');

    return value.copyWith(
      selection: _clampSelectionToIgnoreMarkers(value.selection, value.text),
    );
  }

  String _addLineMarkers(String? string) {
    if (string == null || string.isEmpty) {
      return _lineMarker + _lineMarker;
    }

    return _lineMarker + string + _lineMarker;
  }

  TextSelection _clampSelectionToIgnoreMarkers(
    TextSelection selection,
    String text,
  ) {
    assert(
      text[0] == _lineMarker && text[text.length - 1] == _lineMarker,
      'Cannot call _clampSelectionToIgnoreMarkers for text without line markers.',
    );

    return selection.copyWith(
      baseOffset: selection.baseOffset.clamp(1, text.length - 1),
      extentOffset: selection.extentOffset.clamp(1, text.length - 1),
    );
  }
}
