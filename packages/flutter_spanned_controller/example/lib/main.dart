// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

void main() {
  runApp(MyApp());
}

const bold = BoldAttribute.value;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ScrollController scrollController;
  DocumentController controller;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    controller = DocumentController(scrollController: scrollController);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Boustro'),
        ),
        body: Column(
          children: [
            Expanded(
              child: EditorView(controller: controller),
            ),
            Toolbar(
              documentController: controller,
              buttons: [
                ToolbarButtonData(
                  BoldAttribute.value,
                  (context, t) => const Icon(
                    Icons.format_bold,
                    color: Colors.white,
                  ),
                ),
                ToolbarButtonData(
                  ItalicAttribute.value,
                  (context, t) =>
                      const Icon(Icons.format_italic, color: Colors.white),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditorView extends StatelessWidget {
  EditorView({
    Key key,
    @required this.controller,
  }) : super(key: key);

  DocumentController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, BuiltList<ParagraphController> paragraphs, __) =>
          ListView.builder(
        controller: controller.scrollController,
        itemBuilder: (context, index) {
          return _buildParagraph(context, paragraphs[index]);
        },
        itemCount: paragraphs.length,
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, ParagraphController value) {
    if (value is LineController) {
      return EditorLine(controller: value);
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.red,
          ),
        ),
      );
    }
  }
}

class ParagraphController {
  const ParagraphController({@required this.focusNode});

  final FocusNode focusNode;

  @mustCallSuper
  void dispose() {
    focusNode.dispose();
  }
}

class LineController extends ParagraphController {
  const LineController({
    @required this.controller,
    @required FocusNode focusNode,
  }) : super(focusNode: focusNode);

  final SpannedTextEditingController controller;

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}

class EmbedController extends ParagraphController {
  const EmbedController({
    FocusNode focusNode,
  }) : super(focusNode: focusNode);
}

class DocumentController extends ValueNotifier<BuiltList<ParagraphController>> {
  // Manages paragraphs
  // Keeps track of
  // - SpannedTextController for text
  // - FocusNode for both text and embeds.
  // - ScrollController for scroll view

  // A zero-width-space is used to mark the start of a line.
  // When the ZWS is deleted, the line is deleted and focus is moved
  // to the previous line. Any text left on the deleted line will be
  // merged with the previous line, including style.
  // If there is no previous line the ZWS will not be allowed to be
  // deleted.

  // There should always be a text line at the start and end,
  // they will be trimmed when serialized if empty.

  // Tapping below the editor should focus the last line

  ///
  DocumentController({
    @required this.scrollController,
  }) : super(BuiltList()) {
    insertLine(0);
    insertLine(0);
  }

  final ScrollController scrollController;
  ParagraphController focusedParagraph;

  LineController get focusedLine => focusedParagraph is LineController
      ? focusedParagraph as LineController
      : null;

  void splitLine(int lineIndex, int endFirst, [int startNext]) {
    if (value[lineIndex] is! LineController) {
      throw ArgumentError.value(lineIndex, 'lineIndex',
          'Value at lineIndex needs to be a LineController.');
    }

    startNext ??= endFirst;

    final line = value[lineIndex] as LineController;
    final after = line.controller.spannedText.collapse(before: startNext);
    line.controller.spannedText =
        line.controller.spannedText.collapse(after: endFirst);
    insertLine(lineIndex + 1, after);
  }

  TextEditingValue processTextValue(
    SpannedTextEditingController controller,
    TextEditingValue newValue,
  ) {
    int newLineIndex;
    LineController toFocus;
    final lineIndex = value.indexWhere(
        (ctrl) => ctrl is LineController && ctrl.controller == controller);
    if (lineIndex < 0) {
      return newValue;
    }

    if (!newValue.text.contains('\n')) {
      return newValue;
    }

    final cursor = newValue.selection.isValid
        ? newValue.selection.baseOffset
        : newValue.text.length;
    final diff = SpannedTextEditingController.diffStrings(
      controller.text,
      newValue.text,
      cursor,
    );

    var t = controller.spannedText.applyDiff(diff);

    while ((newLineIndex = t.text.lastIndexOf('\n')) >= 0) {
      final nextLine = t.collapse(before: newLineIndex + 1);
      insertLine(lineIndex + 1, nextLine);
      t = t.collapse(after: newLineIndex);
      toFocus ??= value[lineIndex + 1] as LineController;
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

  LineController insertLine(int index, [SpannedText spannedText]) {
    final spanController = SpannedTextEditingController(
      processTextValue: processTextValue,
      text: spannedText?.text,
      spans: spannedText?.spans?.spans,
    );

    spanController.addListener(() {
      _listener.notify(
        (attr) => spanController.isApplied(attr),
      );
    });

    final focusNode = FocusNode(
      onKey: (n, ev) => _onKey(spanController, ev),
    );

    final newLine = LineController(
      controller: spanController,
      focusNode: focusNode,
    );

    focusNode.addListener(() {
      if (focusNode.hasPrimaryFocus) {
        focusedParagraph = newLine;
        //if (!newLine.controller.selection.isValid) {
        //  newLine.controller.selection =
        //      TextSelection.collapsed(offset: newLine.controller.text.length);
        //}
      } else {
        if (focusedParagraph == newLine) {
          focusedParagraph = null;
        }
      }
    });

    value = value.rebuild((r) => r.insert(index, newLine));
    return newLine;
  }

  KeyEventResult _onKey(
      SpannedTextEditingController controller, RawKeyEvent ev) {
    final selection = controller.value.selection;
    // Try to merge lines when backspace is pressed at the start of
    // a line or delete at the end of a line.
    if (selection.isCollapsed &&
        selection.baseOffset == 0 &&
        (ev.logicalKey == LogicalKeyboardKey.backspace ||
            ev.logicalKey == LogicalKeyboardKey.numpadBackspace)) {
      final index = value.indexWhere(
          (ctrl) => ctrl is LineController && ctrl.controller == controller);
      assert(index >= 0);
      return _tryMergeNext(index - 1);
    } else if (selection.isCollapsed &&
        selection.baseOffset == controller.value.text.length &&
        ev.logicalKey == LogicalKeyboardKey.delete) {
      final index = value.indexWhere(
          (ctrl) => ctrl is LineController && ctrl.controller == controller);
      assert(index >= 0);
      return _tryMergeNext(index);
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _tryMergeNext(int index) {
    if (index < 0 || index + 1 >= value.length) {
      return KeyEventResult.ignored;
    }
    if (value[index] is! LineController ||
        value[index + 1] is! LineController) {
      return KeyEventResult.ignored;
    }
    final c1 = value[index] as LineController;
    final c2 = value[index + 1] as LineController;

    final insertionIndex = c1.controller.text.length;
    final concat = c1.controller.spannedText.concat(c2.controller.spannedText);

    c1.controller.spannedText = concat;
    removeLine(index + 1);
    c1.focusNode.requestFocus();

    // Put the cursor at the insertion point
    c1.controller.selection = c1.controller.selection.copyWith(
      baseOffset: insertionIndex,
      extentOffset: insertionIndex,
    );

    return KeyEventResult.handled;
  }

  /// Remove the line at [index].
  void removeLine(int index) {
    value = value.rebuild((r) => r.removeAt(index));
  }

  final AttributeListener _listener = AttributeListener();

  /// Get a [ValueListenable] that indicates if [attribute]
  /// is applied for the current selection.
  ValueListenable<bool> listen(TextAttribute attribute) {
    return _listener.listen(attribute, false);
  }

  @override
  void dispose() {
    _listener.dispose();
    for (final line in value) {
      line.dispose();
    }
    super.dispose();
  }
}

class EditorLine extends StatefulWidget {
  const EditorLine({
    Key key,
    @required this.controller,
  }) : super(key: key);

  final LineController controller;

  @override
  _EditorLineState createState() => _EditorLineState();
}

class _EditorLineState extends State<EditorLine> {
  @override
  void dispose() {
    //widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      controller: widget.controller.controller,
      focusNode: widget.controller.focusNode,
      maxLines: null,
      style: const TextStyle(fontSize: 16),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

@immutable
class ToolbarButtonData {
  const ToolbarButtonData(
    this.attribute,
    this.builder, {
    this.startBehavior = InsertBehavior.exclusive,
    this.endBehavior = InsertBehavior.inclusive,
  });

  final TextAttribute attribute;
  final InsertBehavior startBehavior;
  final InsertBehavior endBehavior;
  final Widget Function(BuildContext, bool value) builder;
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    Key key,
    @required this.documentController,
    @required this.buttons,
  }) : super(key: key);

  final DocumentController documentController;
  final List<ToolbarButtonData> buttons;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemBuilder: (context, index) {
            final button = buttons[index];
            return ValueListenableBuilder(
              valueListenable: documentController.listen(button.attribute),
              builder: (context, bool value, _) => EditorButton(
                toggled: value,
                onPressed: () =>
                    documentController.focusedLine?.controller?.toggleAttribute(
                  button.attribute,
                  button.startBehavior,
                  button.endBehavior,
                ),
                child: button.builder(context, value),
              ),
            );
          },
          itemCount: buttons.length,
        ),
      ),
    );
  }
}

class EditorButton extends StatelessWidget {
  const EditorButton({
    Key key,
    @required this.toggled,
    this.onPressed,
    this.child,
  }) : super(key: key);

  final bool toggled;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
        child: RawMaterialButton(
          fillColor: toggled ? Colors.grey.shade900 : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
