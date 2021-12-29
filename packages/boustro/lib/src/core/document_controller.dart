import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'document.dart';

/// Event data for [DocumentController.paragraphAddedStream]
@immutable
class ParagraphAddedEvent {
  /// Create a ParagraphEvent.
  const ParagraphAddedEvent(this.controller);

  /// Controller of the paragraph.
  final ParagraphController controller;
}

/// Event data for [DocumentController.paragraphRemovedStream]
@immutable
class ParagraphRemovedEvent {
  /// Create a ParagraphEvent.
  const ParagraphRemovedEvent(this.controller);

  /// Controller of the paragraph.
  final ParagraphController controller;
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
class DocumentController extends ValueNotifier<List<ParagraphController>> {
  /// Create a document controller.
  DocumentController({
    FocusScopeNode? focusNode,
    Iterable<Paragraph> paragraphs = const [],
    DocumentRules? rules,
  })  : rules = rules ?? DefaultDocumentRules(),
        super(paragraphs.map((p) => p.createController()).toList()) {
    _ownedFocusNode = focusNode == null ? FocusScopeNode() : null;
    this.focusNode = focusNode ?? _ownedFocusNode!;

    final state = _MutableDocumentState(value);
    this.rules.enforce(state);
  }

  late final FocusScopeNode? _ownedFocusNode;

  /// The focus scope node for the controller.
  late final FocusScopeNode focusNode;

  final DocumentRules rules;

  // EVENTS

  final StreamController<ParagraphAddedEvent> _paragraphAddedController =
      StreamController.broadcast();

  /// Stream of events fired when a paragraph is added.
  ///
  /// Events are fired before [notifyListeners] is called.
  Stream<ParagraphAddedEvent> get paragraphAddedStream =>
      _paragraphAddedController.stream;

  final StreamController<ParagraphRemovedEvent> _paragraphRemovedController =
      StreamController.broadcast();

  /// Stream of events fired when a paragraph is removed.
  ///
  /// Events are fired before [notifyListeners] is called.
  Stream<ParagraphRemovedEvent> get paragraphRemovedStream =>
      _paragraphRemovedController.stream;

  @protected
  @override
  List<ParagraphController> get value => super.value;

  @protected
  @override
  set value(List<ParagraphController> newValue) {
    if (value != newValue) {
      final oldValue = value;
      super.value = newValue;

      for (final removed in oldValue) {
        final event = ParagraphRemovedEvent(removed);
        _paragraphRemovedController.add(event);
      }
      for (final added in newValue) {
        final event = ParagraphAddedEvent(added);
        _paragraphAddedController.add(event);
      }

      _enforceRules();
    }
  }

  List<ParagraphController> get _paragraphs => value;

  /// Get the paragraphs in this docuent.
  ///
  /// Alias for [value].
  List<ParagraphController> get paragraphs => List.unmodifiable(value);

  /// Sets the paragraphs in this document.
  ///
  /// Alias for [value].
  set paragraphs(List<ParagraphController> newValue) => value = newValue;

  void _enforceRules() {
    final state = _ControllerDocumentState(this);
    rules.enforce(state);
  }

  /// Get the index of the focused paragraph or null if no paragraph has focus.
  int? getFocusedParagraphIndex() {
    final index = paragraphs.indexWhere((p) => p.focusNode.hasFocus);
    return index == -1 ? null : index;
  }

  /// Get the currently focused paragraph, if any.
  ParagraphController? getFocusedParagraph() {
    final index = getFocusedParagraphIndex();
    return index == null ? null : paragraphs[index];
  }

  /// Get the currently focused text paragraph controller, if any.
  TextParagraphControllerMixin? getFocusedText() {
    final focused = getFocusedParagraph();
    return focused is TextParagraphControllerMixin ? focused : null;
  }

  /// Get the contents of this controller represented as a document.
  Document toDocument() {
    final paragraphs =
        this.paragraphs.map((c) => c.toParagraph()).whereNotNull();
    return Document(paragraphs);
  }

  /// Remove the focused paragraph.
  ///
  /// Does nothing if no paragraph is focused.
  void removeCurrentParagraph() {
    final index = getFocusedParagraphIndex();
    if (index != null) {
      removeParagraphAt(index);
    }
  }

  /// Remove the paragraph at [index].
  void removeParagraphAt(int index) => _removeParagraphAt(index, notify: true);

  void _removeParagraphAt(int index, {required bool notify}) {
    if (index < 0 || index >= paragraphs.length) {
      return;
    }

    final controller = _paragraphs.removeAt(index);
    _paragraphRemovedController.add(ParagraphRemovedEvent(controller));

    if (notify) {
      _enforceRules();
      notifyListeners();
    }
  }

  /// Add an embed after all existing paragraphs.
  ParagraphController append(Paragraph paragraph) {
    return insert(paragraphs.length, paragraph);
  }

  /// Insert an embed at the current index.
  ParagraphController? insertAtCurrent(Paragraph paragraph) {
    // We replace the current line if it's empty.
    var index = getFocusedParagraphIndex();
    if (index == null) {
      return null;
    }

    return insert(index + 1, paragraph);
  }

  /// Insert a paragraph at [index].
  ParagraphController insert(int index, Paragraph paragraph) {
    return _insert(index, paragraph, notify: true);
  }

  ParagraphController _insert(
    int index,
    Paragraph paragraph, {
    required bool notify,
  }) {
    final controller = paragraph.createController();
    _paragraphs.insert(index, controller);
    _paragraphAddedController.add(ParagraphAddedEvent(controller));

    if (notify) {
      _enforceRules();
      notifyListeners();
    }

    return controller;
  }

  @override
  void dispose() {
    _paragraphAddedController.close();
    _paragraphRemovedController.close();
    _ownedFocusNode?.dispose();
    super.dispose();
  }
}

abstract class DocumentState {
  List<ParagraphController> get paragraphs;

  ParagraphController append(Paragraph paragraph);

  ParagraphController insert(int index, Paragraph paragraph);

  void removeAt(int index);
}

class _MutableDocumentState implements DocumentState {
  _MutableDocumentState(this.paragraphs);

  final List<ParagraphController> paragraphs;

  @override
  ParagraphController append(Paragraph paragraph) {
    final pc = paragraph.createController();
    paragraphs.add(pc);
    return pc;
  }

  @override
  ParagraphController insert(int index, Paragraph paragraph) {
    final pc = paragraph.createController();
    paragraphs.insert(index, pc);
    return pc;
  }

  @override
  void removeAt(int index) {
    paragraphs.removeAt(index);
  }
}

class _ControllerDocumentState implements DocumentState {
  _ControllerDocumentState(this._controller)
      : paragraphs = _controller.paragraphs;

  final DocumentController _controller;
  final List<ParagraphController> paragraphs;

  @protected
  ParagraphController append(Paragraph paragraph) {
    return _controller._insert(
      paragraphs.length,
      paragraph,
      notify: false,
    );
  }

  @protected
  ParagraphController insert(int index, Paragraph paragraph) {
    return _controller._insert(index, paragraph, notify: false);
  }

  @protected
  void removeAt(int index) {
    _controller._removeParagraphAt(index, notify: false);
  }
}

/// Rules to maintain [DocumentController] invariants.
///
/// [enforce] is called by the [DocumentController] whenever its paragraph
/// list changes, after emitting the [DocumentController.paragraphAddedStream]
/// or [DocumentController.paragraphRemovedStream] event.
///
/// Implementations must call the exposed super class methods rather than
/// the corresponding methods on the [DocumentController].
abstract class DocumentRules {
  const DocumentRules();

  void enforce(DocumentState state);
}

/// The default document rules.
///
/// Maintain the following invariants:
/// - There is always at least one text paragraph.
/// - The first and final paragraph are a text paragraph.
/// - Between any two non-text-paragraphs is a text paragraph.
class DefaultDocumentRules extends DocumentRules {
  const DefaultDocumentRules();

  @override
  @mustCallSuper
  void enforce(DocumentState state) {
    if (state.paragraphs.isEmpty) {
      state.append(TextParagraph());
    }
    if (state.paragraphs.first is! TextParagraphControllerMixin) {
      state.insert(0, TextParagraph());
    }
    if (state.paragraphs.last is! TextParagraphControllerMixin) {
      state.append(TextParagraph());
    }
  }
}
