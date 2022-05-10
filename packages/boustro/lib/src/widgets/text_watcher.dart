import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../core/document.dart';
import '../core/document_controller.dart';
import '../spans/attributed_text_editing_controller.dart';

abstract class TextParagraphListenerWidget extends StatefulWidget {
  const TextParagraphListenerWidget({Key? key}) : super(key: key);

  DocumentController get controller;
  bool get enabled => true;
}

mixin TextParagraphListener<T extends TextParagraphListenerWidget> on State<T> {
  final Map<TextParagraphControllerMixin, VoidCallback> _listeners = {};

  StreamSubscription<ParagraphAddedEvent>? _paragraphAddedSubscription;
  StreamSubscription<ParagraphRemovedEvent>? _paragraphRemovedSubscription;

  void initialize() {
    if (widget.enabled) {
      _paragraphAddedSubscription =
          widget.controller.paragraphAddedStream.listen(onParagraphAdded);
      _paragraphRemovedSubscription =
          widget.controller.paragraphRemovedStream.listen(onParagraphRemoved);

      widget.controller.paragraphs
          .whereType<TextParagraphControllerMixin>()
          .forEach(_listenToController);
    }
  }

  void _listenToController(TextParagraphControllerMixin controller) {
    final listener = () {
      if (mounted) onValueChanged(controller);
    };
    _listeners[controller] = listener;
    controller.textController.addListener(listener);
    onValueChanged(controller);
  }

  @mustCallSuper
  void onParagraphAdded(ParagraphAddedEvent event) {
    final controller = event.controller;
    if (controller is TextParagraphControllerMixin) {
      _listenToController(controller);
    }
  }

  @mustCallSuper
  void onParagraphRemoved(ParagraphRemovedEvent event) {
    final controller = event.controller;
    if (controller is TextParagraphControllerMixin) {
      final listener = _listeners.remove(controller);
      if (listener != null) {
        controller.textController.removeListener(listener);
      }
    }
  }

  void onValueChanged(TextParagraphControllerMixin controller);

  void unregisterAll() {
    _paragraphAddedSubscription?.cancel();
    _paragraphRemovedSubscription?.cancel();
    _paragraphAddedSubscription = null;
    _paragraphRemovedSubscription = null;
    for (final entry in _listeners.entries) {
      entry.key.textController.removeListener(entry.value);
    }
    _listeners.clear();
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      unregisterAll();
      initialize();
    } else if (widget.enabled && !oldWidget.enabled) {
      initialize();
    } else if (!widget.enabled && oldWidget.enabled) {
      unregisterAll();
    }
  }

  @override
  void dispose() {
    unregisterAll();
    super.dispose();
  }
}

/// Widget that watches for text changes in the focused text widget.
class FocusedTextParagraphWatcher<T> extends TextParagraphListenerWidget {
  const FocusedTextParagraphWatcher({
    Key? key,
    required this.enabled,
    required this.controller,
    required this.select,
    required this.defaultValue,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  final bool enabled;

  @override
  final DocumentController controller;

  final T Function(AttributedTextEditingController) select;
  final T defaultValue;
  final Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  ) builder;

  final Widget? child;

  @override
  _FocusedTextParagraphWatcherState<T> createState() =>
      _FocusedTextParagraphWatcherState<T>();
}

class _FocusedTextParagraphWatcherState<T>
    extends State<FocusedTextParagraphWatcher<T>> with TextParagraphListener {
  late T _lastValue = widget.defaultValue;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      initialize();
    }
    // TODO handle focus loss
  }

  @override
  void didUpdateWidget(FocusedTextParagraphWatcher<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.select != oldWidget.select) {
      final focused =
          _listeners.keys.firstWhereOrNull((c) => c.focusNode.hasFocus);
      if (focused != null) {
        onValueChanged(focused);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _lastValue, widget.child);
  }

  @override
  void onValueChanged(TextParagraphControllerMixin controller) {
    if (!controller.focusNode.hasFocus) {
      return;
    }

    final value = widget.select(controller.textController);
    if (value != _lastValue) {
      setState(() {
        _lastValue = value;
      });
    }
  }
}
