import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import '../document.dart';
import 'editor.dart';

/// Holds state for a paragraph of a boustro document.
@immutable
abstract class ParagraphState {
  /// Create a paragraph.
  const ParagraphState({required FocusNode focusNode}) : _focusNode = focusNode;

  /// Use to focus this paragraph.
  final FocusNode _focusNode;
  FocusNode get focusNode => _focusNode;

  @mustCallSuper
  void dispose() {
    focusNode.dispose();
  }

  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  });
}

/// Holds focus node and state for a line of text.
@immutable
class LineState extends ParagraphState {
  /// Create a text line.
  LineState({
    required this.controller,
    required FocusNode focusNode,
    BuiltMap<String, Object>? properties,
  })  : properties = properties ?? BuiltMap<String, Object>(),
        super(focusNode: focusNode);

  LineState withProperties(
    Map<String, dynamic> properties,
  ) {
    return LineState(
      controller: controller,
      focusNode: focusNode,
      properties: BuiltMap.from(properties),
    );
  }

  /// The [TextEditingController] that manages the text
  /// and markup of this line.
  final SpannedTextEditingController controller;

  /// Properties that can affect how this line is displayed.
  final BuiltMap<String, Object> properties;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  }) =>
      line(this);
}

/// Holds [FocusNode] for a boustro embed.
@immutable
class EmbedState extends ParagraphState {
  /// Create an embed.
  const EmbedState({
    required FocusNode focusNode,
    required this.content,
  }) : super(focusNode: focusNode);

  EmbedState withValue(Object value) {
    return EmbedState(
      focusNode: focusNode,
      content: content.withValue(value),
    );
  }

  /// Content of the embed.
  final BoustroParagraphEmbed content;

  @override
  void dispose() {
    (content.value as dynamic).dispose?.call();
    super.dispose();
  }

  @override
  T match<T>({
    required T Function(LineState) line,
    required T Function(EmbedState) embed,
  }) =>
      embed(this);
}

/// Manages the contents of a [BoustroEditor].
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
    ScrollController? scrollController,
    Iterable<BoustroParagraph>? paragraphs,
  })  : scrollController = scrollController ?? ScrollController(),
        super(BuiltList()) {
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

  /// Get the scroll controller for the [ScrollView] containing the paragraphs.
  final ScrollController scrollController;

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

  /// Get the index of the focused paragraph or -1 if no paragrap has focus.
  int get focusedParagraphIndex =>
      paragraphs.indexWhere((p) => p.focusNode.hasPrimaryFocus);

  /// Get the currently focused paragraph, if any.
  ParagraphState? get focusedParagraph {
    final index = focusedParagraphIndex;
    return index == -1 ? null : paragraphs[index];
  }

  /// Get the currently focused line. If there is no focused paragraph or the
  /// [focusedParagraph] is not a [LineState] this returns null.
  LineState? get focusedLine =>
      focusedParagraph is LineState ? focusedParagraph as LineState? : null;

  TextEditingValue _processTextValue(
    SpannedTextEditingController controller,
    TextEditingValue newValue,
  ) {
    int newLineIndex;
    LineState? toFocus;

    if (!newValue.text.contains('\n')) {
      return newValue;
    }

    final lineIndex = paragraphs.indexWhere(
        (ctrl) => ctrl is LineState && identical(ctrl.controller, controller));
    assert(lineIndex >= 0, 'processTextValue called with missing controller.');

    final currentLine = paragraphs[lineIndex] as LineState;
    final cursor = newValue.selection.isValid
        ? newValue.selection.baseOffset
        : newValue.text.length;
    final diff = SpannedTextEditingController.diffStrings(
      controller.text,
      newValue.text,
      cursor,
    );

    var t = controller.spannedString.applyDiff(diff);

    while ((newLineIndex = t.text.lastIndexOf('\n')) >= 0) {
      final nextLine = t.collapse(before: newLineIndex + 1);
      insertLine(
          lineIndex + 1,
          BoustroLine.fromSpanned(nextLine,
              properties: currentLine.properties));
      t = t.collapse(after: newLineIndex);
      toFocus ??= paragraphs[lineIndex + 1] as LineState;
    }

    if (toFocus != null) {
      toFocus.focusNode.requestFocus();
      toFocus.controller.selection = toFocus.controller.selection.copyWith(
        baseOffset: 0,
        extentOffset: 0,
      );
    }
    return TextEditingValue(
      text: t.text,
      selection: newValue.selection.copyWith(
        baseOffset: t.length,
        extentOffset: t.length,
      ),
    );
  }

  /// Get the contents of this controller represented as a boustro document.
  BoustroDocument toDocument() {
    final paragraphs = this
        .paragraphs
        .map((p) => p.match<BoustroParagraph>(
              line: (l) => BoustroLine.fromSpanned(l.controller.spannedString),
              // TODO need a controller to modify embed state.
              embed: (e) => e.content,
            ))
        .toBuiltList();
    return BoustroDocument(paragraphs);
  }

  /// Add a line after all existing paragraphs.
  LineState appendLine([BoustroLine? line]) {
    return insertLine(paragraphs.length, line);
  }

  /// Insert a line at [index].
  LineState insertLine(int index, [BoustroLine? line]) {
    final spanController = SpannedTextEditingController(
      processTextValue: _processTextValue,
      text: line?.text,
      spans: line?.spanList.spans,
    );

    spanController.addListener(() {
      _listener.notify(
        spanController.isApplied,
      );
    });

    final focusNode = FocusNode(
      onKey: (n, ev) => _onKey(spanController, ev),
    );

    final newLine = LineState(
      controller: spanController,
      focusNode: focusNode,
      properties: line?.properties,
    );

    _rebuild((r) => r.insert(index, newLine));
    return newLine;
  }

  void setLineProperties(LineState line, Map<String, dynamic> properties) {
    final lineIndex = paragraphs.indexWhere((l) => l is LineState && l == line);
    if (lineIndex < 0) {
      throw ArgumentError.value(
          line, 'line', 'line must be a member of this document.');
    }

    final newLine = line.withProperties(properties);

    _rebuild(
      (b) => b[lineIndex] = newLine,
    );
  }

  /// Remove the line at [index].
  void removeLine(int index) {
    _rebuild((r) {
      final state = r.removeAt(index);
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
  EmbedState appendEmbed(BoustroParagraphEmbed embed) {
    return insertEmbed(paragraphs.length, embed);
  }

  /// Insert an embed at the current index.
  EmbedState? insertEmbedAtCurrent(BoustroParagraphEmbed embed) {
    // We replace the current line if it's empty.
    final index = focusedParagraphIndex;
    if (index == -1) {
      return null;
    }
    if (0 < index && index < paragraphs.length) {
      final p = paragraphs[index];
      if (p is LineState && p.controller.text.isEmpty) {
        removeLine(index);
      }
    }
    return insertEmbed(index, embed);
  }

  /// Insert an embed at [index].
  EmbedState insertEmbed(int index, BoustroParagraphEmbed embed) {
    final focus = FocusNode();
    final state = EmbedState(focusNode: focus, content: embed);

    if (index == 0) {
      insertLine(0);
    }
    _rebuild((r) {
      r.insert(index == 0 ? 1 : index, state);
    });
    if (index == paragraphs.length) {
      appendLine();
    }
    return state;
  }

  // Key handler for handling backspace and delete in line paragraphs.
  KeyEventResult _onKey(
      SpannedTextEditingController controller, RawKeyEvent ev) {
    final selection = controller.value.selection;
    // Try to merge lines when backspace is pressed at the start of
    // a line or delete at the end of a line.
    if (selection.isCollapsed &&
        selection.baseOffset == 0 &&
        (ev.logicalKey == LogicalKeyboardKey.backspace ||
            ev.logicalKey == LogicalKeyboardKey.numpadBackspace)) {
      final index = paragraphs.indexWhere(
          (ctrl) => ctrl is LineState && ctrl.controller == controller);
      assert(index >= 0, 'onKey callback from missing controller');

      final line = paragraphs[index] as LineState;
      if (line.properties.isNotEmpty) {
        _rebuild(
          (b) => b[index] = line.withProperties(<String, dynamic>{}),
        );
        return KeyEventResult.handled;
      } else {
        return _tryMergeNext(index - 1);
      }
    } else if (selection.isCollapsed &&
        selection.baseOffset == controller.value.text.length &&
        ev.logicalKey == LogicalKeyboardKey.delete) {
      final index = paragraphs.indexWhere(
          (ctrl) => ctrl is LineState && ctrl.controller == controller);
      assert(index >= 0, 'onKey callback from missing controller');
      return _tryMergeNext(index);
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _tryMergeNext(int index) {
    if (index < 0 || index + 1 >= paragraphs.length) {
      return KeyEventResult.ignored;
    }
    if (paragraphs[index] is! LineState ||
        paragraphs[index + 1] is! LineState) {
      return KeyEventResult.ignored;
    }
    final c1 = paragraphs[index] as LineState;
    final c2 = paragraphs[index + 1] as LineState;

    final insertionIndex = c1.controller.text.length;
    final concat =
        c1.controller.spannedString.concat(c2.controller.spannedString);

    c1.controller.spannedString = concat;
    removeLine(index + 1);
    c1.focusNode.requestFocus();

    // Put the cursor at the insertion point
    c1.controller.selection = c1.controller.selection.copyWith(
      baseOffset: insertionIndex,
      extentOffset: insertionIndex,
    );

    return KeyEventResult.handled;
  }

  final AttributeListener _listener = AttributeListener();

  /// Get a [ValueListenable] that indicates if [attribute]
  /// is applied for the current selection.
  ValueListenable<bool> listen(TextAttribute attribute) {
    return _listener.listen(attribute, initialValue: false);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}
