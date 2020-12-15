import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../context.dart';
import 'editor.dart';
import 'toolbar.dart';

/// Provides theming for boustro widgets.
class BoustroTheme extends InheritedTheme {
  /// Creates a boustro theme that controls the configuration
  /// of various descendant boustro widgets.
  const BoustroTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  /// The properties to apply to descendant boustro widgets.
  final BoustroThemeData data;

  /// Returns the [data] from the closest [BoustroTheme] ancestor. If there is
  /// no ancestor, it returns [BoustroThemeData.light] or
  /// [BoustroThemeData.dark] depending on the [Theme]'s brightness.
  static BoustroThemeData of(BuildContext context) {
    final boustroTheme =
        context.dependOnInheritedWidgetOfExactType<BoustroTheme>();
    if (boustroTheme != null) {
      return boustroTheme.data;
    }
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? BoustroThemeData.light
        : BoustroThemeData.dark;
  }

  @override
  bool updateShouldNotify(covariant BoustroTheme oldWidget) {
    return oldWidget.data != data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return BoustroTheme(data: data, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoustroThemeData>('data', data));
  }
}

/// Contains data for [BoustroTheme].
class BoustroThemeData extends Equatable {
  /// Create a boustro theme with all properties set.
  const BoustroThemeData.raw({
    required this.editorColor,
    required this.editorPadding,
    required this.toolbarDecoration,
    required this.toolbarHeight,
    required this.toolbarItemExtent,
    required this.toolbarPadding,
    required this.toolbarFadeDuration,
    required this.linePadding,
    required this.embedPadding,
  });

  /// Default theme for [brightness].
  ///
  /// Either [BoustroThemeData.light] or [BoustroThemeData.dark].
  factory BoustroThemeData._fallback({
    required Brightness brightness,
  }) {
    final light = brightness == Brightness.light;
    return BoustroThemeData.raw(
      editorColor: light ? Colors.grey.shade100 : Colors.grey.shade700,
      editorPadding: const EdgeInsets.only(top: 8, bottom: 150),
      toolbarDecoration: BoxDecoration(
        color: light ? Colors.grey.shade200 : Colors.grey.shade800,
        border:
            light ? Border(top: BorderSide(color: Colors.grey.shade300)) : null,
      ),
      toolbarHeight: 48,
      toolbarItemExtent: 44,
      toolbarPadding: const EdgeInsets.symmetric(horizontal: 4),
      toolbarFadeDuration: const Duration(milliseconds: 200),
      linePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      embedPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  /// Default boustro theme for [brightness]. Has a non-null value for all
  /// fields.
  factory BoustroThemeData.fallback({required Brightness brightness}) =>
      brightness == Brightness.light ? light : dark;

  /// Default boustro theme for [theme]. Has a non-null value for all
  /// fields.
  factory BoustroThemeData.fallbackForTheme(ThemeData theme) =>
      theme.brightness == Brightness.light ? light : dark;

  /// Default boustro theme for [context]. Has a non-null value for all
  /// fields.
  factory BoustroThemeData.fallbackForContext(BuildContext context) =>
      BoustroThemeData.fallbackForTheme(Theme.of(context));

  factory BoustroThemeData._light() =>
      BoustroThemeData._fallback(brightness: Brightness.light);

  factory BoustroThemeData._dark() =>
      BoustroThemeData._fallback(brightness: Brightness.dark);

  /// Default light theme. Has a non-null value for all fields.
  static late BoustroThemeData light = BoustroThemeData._light();

  /// Default dark theme. Has a non-null value for all fields.
  static late BoustroThemeData dark = BoustroThemeData._dark();

  /// Create a copy of this theme with passed fields replaced with the new
  /// value.
  BoustroThemeData copyWith({
    Color? editorColor,
    EdgeInsetsGeometry? editorPadding,
    double? editorFreeSpace,
    BoxDecoration? toolbarDecoration,
    double? toolbarHeight,
    double? toolbarItemExtent,
    EdgeInsetsGeometry? toolbarPadding,
    Duration? toolbarFadeDuration,
    EdgeInsetsGeometry? linePadding,
    EdgeInsetsGeometry? embedPadding,
  }) {
    return BoustroThemeData.raw(
      editorColor: editorColor ?? this.editorColor,
      editorPadding: editorPadding ?? this.editorPadding,
      toolbarDecoration: toolbarDecoration ?? this.toolbarDecoration,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      toolbarItemExtent: toolbarItemExtent ?? this.toolbarItemExtent,
      toolbarPadding: toolbarPadding ?? this.toolbarPadding,
      toolbarFadeDuration: toolbarFadeDuration ?? this.toolbarFadeDuration,
      linePadding: linePadding ?? this.linePadding,
      embedPadding: embedPadding ?? this.embedPadding,
    );
  }

  /// Background color of a [BoustroEditor].
  final Color? editorColor;

  /// Padding inside the scrollable part of a [BoustroEditor].
  final EdgeInsetsGeometry? editorPadding;

  /// Color and decoration for a [Toolbar].
  final BoxDecoration? toolbarDecoration;

  /// Height of a [Toolbar].
  final double? toolbarHeight;

  /// Extent for items in [Toolbar].
  final double? toolbarItemExtent;

  /// Padding around [Toolbar]. [toolbarDecoration] is
  /// outside of this padding and the items are inside it.
  final EdgeInsetsGeometry? toolbarPadding;

  /// Duration to crossfade when the toolbar items change (because of a nested
  /// menu).
  final Duration? toolbarFadeDuration;

  /// Padding for lines of text.
  ///
  /// The horizontal part of this padding is applied outside of any
  /// [LineParagraphModifier]s, while the vertical part is applied inside of
  /// them.
  final EdgeInsetsGeometry? linePadding;

  /// Padding for embeds.
  final EdgeInsetsGeometry? embedPadding;

  @override
  List<Object?> get props => [
        editorColor,
        editorPadding,
        toolbarDecoration,
        toolbarHeight,
        toolbarItemExtent,
        toolbarPadding,
        toolbarFadeDuration,
        linePadding,
        embedPadding,
      ];

  /// Linearly interpolate between two boustro themes.
  ///
  /// Used by [AnimatedBoustroTheme] to animate between themes.
  static BoustroThemeData lerp(
      BoustroThemeData a, BoustroThemeData b, double t) {
    return BoustroThemeData.raw(
      editorColor: Color.lerp(a.editorColor, b.editorColor, t),
      editorPadding:
          EdgeInsetsGeometry.lerp(a.editorPadding, b.editorPadding, t),
      toolbarDecoration:
          BoxDecoration.lerp(a.toolbarDecoration, b.toolbarDecoration, t),
      toolbarHeight: ui.lerpDouble(a.toolbarHeight, b.toolbarHeight, t),
      toolbarItemExtent:
          ui.lerpDouble(a.toolbarItemExtent, b.toolbarItemExtent, t),
      toolbarPadding:
          EdgeInsetsGeometry.lerp(a.toolbarPadding, b.toolbarPadding, t),
      toolbarFadeDuration:
          t < 0.5 ? a.toolbarFadeDuration : b.toolbarFadeDuration,
      linePadding: EdgeInsetsGeometry.lerp(a.linePadding, b.linePadding, t),
      embedPadding: EdgeInsetsGeometry.lerp(a.embedPadding, b.embedPadding, t),
    );
  }
}

/// An interpolation between two [BoustroThemeData]s.
///
/// This class specializes the interpolation of [Tween<BoustroThemeData>] to call the
/// [BoustroThemeData.lerp] method.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class BoustroThemeDataTween extends Tween<BoustroThemeData> {
  /// Creates a [BoustroThemeData] tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  BoustroThemeDataTween({BoustroThemeData? begin, BoustroThemeData? end})
      : super(begin: begin, end: end);

  @override
  BoustroThemeData lerp(double t) => BoustroThemeData.lerp(begin!, end!, t);
}

/// Animated version of [BoustroTheme] which automatically transitions the colors,
/// etc, over a given duration whenever the given theme changes.
///
/// Here's an illustration of what using this widget looks like, using a [curve]
/// of [Curves.elasticInOut].
/// {@animation 250 266 https://flutter.github.io/assets-for-api-docs/assets/widgets/animated_theme.mp4}
///
/// See also:
///
///  * [BoustroTheme], which [AnimatedBoustroTheme] uses to actually apply the interpolated
///    theme.
///  * [BoustroThemeData], which describes the actual configuration of a theme.
///  * [MaterialApp], which includes an [AnimatedBoustroTheme] widget configured via
///    the [MaterialApp.theme] argument.
class AnimatedBoustroTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme.
  ///
  /// By default, the theme transition uses a linear curve. The [data] and
  /// [child] arguments must not be null.
  const AnimatedBoustroTheme({
    Key? key,
    required this.data,
    Curve curve = Curves.linear,
    Duration duration = kThemeAnimationDuration,
    VoidCallback? onEnd,
    required this.child,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  /// The properties to apply to descendant boustro widgets.
  final BoustroThemeData data;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _AnimatedBoustroThemeState createState() => _AnimatedBoustroThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoustroThemeData>('data', data));
  }
}

class _AnimatedBoustroThemeState
    extends AnimatedWidgetBaseState<AnimatedBoustroTheme> {
  BoustroThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // TODO(ianh): Use constructor tear-offs when it becomes possible, https://github.com/dart-lang/sdk/issues/10659
    _data = visitor(
            _data,
            widget.data,
            (dynamic value) =>
                BoustroThemeDataTween(begin: value as BoustroThemeData))!
        as BoustroThemeDataTween;
  }

  @override
  Widget build(BuildContext context) {
    return BoustroTheme(
      data: _data!.evaluate(animation!),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<BoustroThemeDataTween>('data', _data,
        showName: false, defaultValue: null));
  }
}
