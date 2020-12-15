// ignore_for_file: diagnostic_describe_all_properties

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Inherited widget containing all fields from [GestureDetector]. Used by
/// embeds to handle gestures.
class EmbedGestureHandler<T> extends InheritedWidget {
  /// Create an embed gesture handler.
  const EmbedGestureHandler({
    Key? key,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onTertiaryTapCancel,
    this.onDoubleTapDown,
    this.onDoubleTap,
    this.onDoubleTapCancel,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onSecondaryLongPress,
    this.onSecondaryLongPressStart,
    this.onSecondaryLongPressMoveUpdate,
    this.onSecondaryLongPressUp,
    this.onSecondaryLongPressEnd,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onForcePressStart,
    this.onForcePressPeak,
    this.onForcePressUpdate,
    this.onForcePressEnd,
    this.behavior,
    this.excludeFromSemantics = false,
    this.dragStartBehavior = DragStartBehavior.start,
    required Widget child,
  }) : super(key: key, child: child);

  /// See [GestureDetector.onTapDown].
  final GestureTapDownCallback? onTapDown;

  /// See [GestureDetector.onTapUp].
  final GestureTapUpCallback? onTapUp;

  /// See [GestureDetector.onTap].
  final GestureTapCallback? onTap;

  /// See [GestureDetector.onTapCancel].
  final GestureTapCancelCallback? onTapCancel;

  /// See [GestureDetector.onSecondaryTap].
  final GestureTapCallback? onSecondaryTap;

  /// See [GestureDetector.onSecondaryTapDown].
  final GestureTapDownCallback? onSecondaryTapDown;

  /// See [GestureDetector.onSecondaryTapUp].
  final GestureTapUpCallback? onSecondaryTapUp;

  /// See [GestureDetector.onSecondaryTapCancel].
  final GestureTapCancelCallback? onSecondaryTapCancel;

  /// See [GestureDetector.onTertiaryTapDown].
  final GestureTapDownCallback? onTertiaryTapDown;

  /// See [GestureDetector.onTertiaryTapUp].
  final GestureTapUpCallback? onTertiaryTapUp;

  /// See [GestureDetector.onTertiaryTapCancel].
  final GestureTapCancelCallback? onTertiaryTapCancel;

  /// See [GestureDetector.onDoubleTapDown].
  final GestureTapDownCallback? onDoubleTapDown;

  /// See [GestureDetector.onDoubleTap].
  final GestureTapCallback? onDoubleTap;

  /// See [GestureDetector.onDoubleTapCancel].
  final GestureTapCancelCallback? onDoubleTapCancel;

  /// See [GestureDetector.onLongPress].
  final GestureLongPressCallback? onLongPress;

  /// See [GestureDetector.onLongPressStart].
  final GestureLongPressStartCallback? onLongPressStart;

  /// See [GestureDetector.onLongPressMoveUpdate].
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  /// See [GestureDetector.onLongPressUp].
  final GestureLongPressUpCallback? onLongPressUp;

  /// See [GestureDetector.onLongPressEnd].
  final GestureLongPressEndCallback? onLongPressEnd;

  /// See [GestureDetector.onSecondaryLongPress].
  final GestureLongPressCallback? onSecondaryLongPress;

  /// See [GestureDetector.onSecondaryLongPressStart].
  final GestureLongPressStartCallback? onSecondaryLongPressStart;

  /// See [GestureDetector.onSecondaryLongPressMoveUpdate].
  final GestureLongPressMoveUpdateCallback? onSecondaryLongPressMoveUpdate;

  /// See [GestureDetector.onSecondaryLongPressUp].
  final GestureLongPressUpCallback? onSecondaryLongPressUp;

  /// See [GestureDetector.onSecondaryLongPressEnd].
  final GestureLongPressEndCallback? onSecondaryLongPressEnd;

  /// See [GestureDetector.onVerticalDragDown].
  final GestureDragDownCallback? onVerticalDragDown;

  /// See [GestureDetector.onVerticalDragStart].
  final GestureDragStartCallback? onVerticalDragStart;

  /// See [GestureDetector.onVerticalDragUpdate].
  final GestureDragUpdateCallback? onVerticalDragUpdate;

  /// See [GestureDetector.onVerticalDragEnd].
  final GestureDragEndCallback? onVerticalDragEnd;

  /// See [GestureDetector.onVerticalDragCancel].
  final GestureDragCancelCallback? onVerticalDragCancel;

  /// See [GestureDetector.onHorizontalDragDown].
  final GestureDragDownCallback? onHorizontalDragDown;

  /// See [GestureDetector.onHorizontalDragStart].
  final GestureDragStartCallback? onHorizontalDragStart;

  /// See [GestureDetector.onHorizontalDragUpdate].
  final GestureDragUpdateCallback? onHorizontalDragUpdate;

  /// See [GestureDetector.onHorizontalDragEnd].
  final GestureDragEndCallback? onHorizontalDragEnd;

  /// See [GestureDetector.onHorizontalDragCancel].
  final GestureDragCancelCallback? onHorizontalDragCancel;

  /// See [GestureDetector.onPanDown].
  final GestureDragDownCallback? onPanDown;

  /// See [GestureDetector.onPanStart].
  final GestureDragStartCallback? onPanStart;

  /// See [GestureDetector.onPanUpdate].
  final GestureDragUpdateCallback? onPanUpdate;

  /// See [GestureDetector.onPanEnd].
  final GestureDragEndCallback? onPanEnd;

  /// See [GestureDetector.onPanCancel].
  final GestureDragCancelCallback? onPanCancel;

  /// See [GestureDetector.onScaleStart].
  final GestureScaleStartCallback? onScaleStart;

  /// See [GestureDetector.onScaleUpdate].
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// See [GestureDetector.onScaleEnd].
  final GestureScaleEndCallback? onScaleEnd;

  /// See [GestureDetector.onForcePressStart].
  final GestureForcePressStartCallback? onForcePressStart;

  /// See [GestureDetector.onForcePressPeak].
  final GestureForcePressPeakCallback? onForcePressPeak;

  /// See [GestureDetector.onForcePressUpdate].
  final GestureForcePressUpdateCallback? onForcePressUpdate;

  /// See [GestureDetector.onForcePressEnd].
  final GestureForcePressEndCallback? onForcePressEnd;

  /// See [GestureDetector.behavior].
  final HitTestBehavior? behavior;

  /// See [GestureDetector.excludeFromSemantics].
  final bool excludeFromSemantics;

  /// See [GestureDetector.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  @override
  bool updateShouldNotify(covariant EmbedGestureHandler<T> oldWidget) {
    return onTapDown != oldWidget.onTapDown ||
        onTapUp != oldWidget.onTapUp ||
        onTap != oldWidget.onTap ||
        onTapCancel != oldWidget.onTapCancel ||
        onSecondaryTap != oldWidget.onSecondaryTap ||
        onSecondaryTapDown != oldWidget.onSecondaryTapDown ||
        onSecondaryTapUp != oldWidget.onSecondaryTapUp ||
        onSecondaryTapCancel != oldWidget.onSecondaryTapCancel ||
        onTertiaryTapDown != oldWidget.onTertiaryTapDown ||
        onTertiaryTapUp != oldWidget.onTertiaryTapUp ||
        onTertiaryTapCancel != oldWidget.onTertiaryTapCancel ||
        onDoubleTapDown != oldWidget.onDoubleTapDown ||
        onDoubleTap != oldWidget.onDoubleTap ||
        onDoubleTapCancel != oldWidget.onDoubleTapCancel ||
        onLongPress != oldWidget.onLongPress ||
        onLongPressStart != oldWidget.onLongPressStart ||
        onLongPressMoveUpdate != oldWidget.onLongPressMoveUpdate ||
        onLongPressUp != oldWidget.onLongPressUp ||
        onLongPressEnd != oldWidget.onLongPressEnd ||
        onSecondaryLongPress != oldWidget.onSecondaryLongPress ||
        onSecondaryLongPressStart != oldWidget.onSecondaryLongPressStart ||
        onSecondaryLongPressMoveUpdate !=
            oldWidget.onSecondaryLongPressMoveUpdate ||
        onSecondaryLongPressUp != oldWidget.onSecondaryLongPressUp ||
        onSecondaryLongPressEnd != oldWidget.onSecondaryLongPressEnd ||
        onVerticalDragDown != oldWidget.onVerticalDragDown ||
        onVerticalDragStart != oldWidget.onVerticalDragStart ||
        onVerticalDragUpdate != oldWidget.onVerticalDragUpdate ||
        onVerticalDragEnd != oldWidget.onVerticalDragEnd ||
        onVerticalDragCancel != oldWidget.onVerticalDragCancel ||
        onHorizontalDragDown != oldWidget.onHorizontalDragDown ||
        onHorizontalDragStart != oldWidget.onHorizontalDragStart ||
        onHorizontalDragUpdate != oldWidget.onHorizontalDragUpdate ||
        onHorizontalDragEnd != oldWidget.onHorizontalDragEnd ||
        onHorizontalDragCancel != oldWidget.onHorizontalDragCancel ||
        onPanDown != oldWidget.onPanDown ||
        onPanStart != oldWidget.onPanStart ||
        onPanUpdate != oldWidget.onPanUpdate ||
        onPanEnd != oldWidget.onPanEnd ||
        onPanCancel != oldWidget.onPanCancel ||
        onScaleStart != oldWidget.onScaleStart ||
        onScaleUpdate != oldWidget.onScaleUpdate ||
        onScaleEnd != oldWidget.onScaleEnd ||
        onForcePressStart != oldWidget.onForcePressStart ||
        onForcePressPeak != oldWidget.onForcePressPeak ||
        onForcePressUpdate != oldWidget.onForcePressUpdate ||
        onForcePressEnd != oldWidget.onForcePressEnd ||
        behavior != oldWidget.behavior ||
        excludeFromSemantics != oldWidget.excludeFromSemantics ||
        dragStartBehavior != oldWidget.dragStartBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        EnumProperty<DragStartBehavior>('startBehavior', dragStartBehavior));
  }

  /// Build a [GestureDetector] with the values from this handler and the given
  /// child.
  Widget toDetector({
    Widget? child,
  }) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTap: onTap,
      onTapCancel: onTapCancel,
      onSecondaryTap: onSecondaryTap,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp,
      onSecondaryTapCancel: onSecondaryTapCancel,
      onTertiaryTapDown: onTertiaryTapDown,
      onTertiaryTapUp: onTertiaryTapUp,
      onTertiaryTapCancel: onTertiaryTapCancel,
      onDoubleTapDown: onDoubleTapDown,
      onDoubleTap: onDoubleTap,
      onDoubleTapCancel: onDoubleTapCancel,
      onLongPress: onLongPress,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressUp: onLongPressUp,
      onLongPressEnd: onLongPressEnd,
      onSecondaryLongPress: onSecondaryLongPress,
      onSecondaryLongPressStart: onSecondaryLongPressStart,
      onSecondaryLongPressMoveUpdate: onSecondaryLongPressMoveUpdate,
      onSecondaryLongPressUp: onSecondaryLongPressUp,
      onSecondaryLongPressEnd: onSecondaryLongPressEnd,
      onVerticalDragDown: onVerticalDragDown,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onVerticalDragCancel: onVerticalDragCancel,
      onHorizontalDragDown: onHorizontalDragDown,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      onHorizontalDragCancel: onHorizontalDragCancel,
      onPanDown: onPanDown,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      onForcePressStart: onForcePressStart,
      onForcePressPeak: onForcePressPeak,
      onForcePressUpdate: onForcePressUpdate,
      onForcePressEnd: onForcePressEnd,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      dragStartBehavior: dragStartBehavior,
      child: child,
    );
  }
}
