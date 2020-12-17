import 'dart:ui' as ui;

import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../document.dart';
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
  /// [LineModifier]s, while the vertical part is applied inside of
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
/// See also:
///
///  * [BoustroTheme], which [AnimatedBoustroTheme] uses to actually apply the interpolated
///    theme.
///  * [BoustroThemeData], which describes the actual configuration of a theme.
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

  /// The configuration of this theme.
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

/// Theme for custom components in boustro, like embeds and line modifiers.
class BoustroComponentTheme extends InheritedTheme {
  /// Create a boustro component theme.
  const BoustroComponentTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  /// The configuration of this theme.
  final BoustroComponentThemeData data;

  /// Returns the [data] from the closest [BoustroTheme] ancestor. If there is
  /// no ancestor, it returns [BoustroThemeData.light] or
  /// [BoustroThemeData.dark] depending on the [Theme]'s brightness.
  static BoustroComponentThemeData of(BuildContext context) {
    final boustroTheme =
        context.dependOnInheritedWidgetOfExactType<BoustroComponentTheme>();
    if (boustroTheme != null) {
      return boustroTheme.data;
    }
    return BoustroComponentThemeData.empty();
  }

  @override
  bool updateShouldNotify(covariant BoustroComponentTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return BoustroComponentTheme(data: data, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<BoustroComponentThemeData>('data', data));
  }
}

/// Theme data object for [BoustroComponentTheme].
class BoustroComponentThemeData extends Equatable {
  /// Create a theme data object with the provided property map.
  const BoustroComponentThemeData(this.properties);

  /// Create a theme data object with no properties set.
  BoustroComponentThemeData.empty() : this(BuiltMap());

  /// Map of properties set on this theme.
  final BuiltMap<String, ThemeProperty<dynamic>> properties;

  /// Get the value of a property in this theme.
  T? get<T>(String key) {
    return properties[key]?.value as T?;
  }

  /// Rebuild this theme data by applying updates to a [ComponentThemeBuilder].
  BoustroComponentThemeData rebuild(
      dynamic Function(ComponentThemeBuilder) updates) {
    final builder = ComponentThemeBuilder(properties.toMap());
    updates(builder);
    return builder.build();
  }

  @override
  List<Object?> get props => [properties];

  /// Linearly interpolate between two boustro themes.
  ///
  /// Used by [AnimatedBoustroComponentTheme] to animate between themes.
  static BoustroComponentThemeData lerp(
      BoustroComponentThemeData a, BoustroComponentThemeData b, double t) {
    final map = <String, ThemeProperty<dynamic>>{};
    final keys = a.properties.keys.toSet()..addAll(b.properties.keys);
    for (final key in keys) {
      final v1 = a.properties[key];
      final v2 = b.properties[key];

      if (v1 == null) {
        map[key] = v2!;
      } else if (v2 == null) {
        map[key] = v1;
      } else {
        map[key] = v1.lerp(v2, t);
      }
    }

    return BoustroComponentThemeData(map.build());
  }
}

/// An interpolation between two [BoustroThemeData]s.
///
/// This class specializes the interpolation of [Tween<BoustroThemeData>] to call the
/// [BoustroThemeData.lerp] method.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class BoustroComponentThemeDataTween extends Tween<BoustroComponentThemeData> {
  /// Creates a [BoustroComponentThemeData] tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  BoustroComponentThemeDataTween(
      {BoustroComponentThemeData? begin, BoustroComponentThemeData? end})
      : super(begin: begin, end: end);

  @override
  BoustroComponentThemeData lerp(double t) =>
      BoustroComponentThemeData.lerp(begin!, end!, t);
}

/// Animated version of [BoustroComponentTheme] which automatically transitions
/// the colors, etc, over a given duration whenever the given theme changes.
///
/// See also:
///
///  * [BoustroComponentTheme], which [AnimatedBoustroComponentTheme] uses to actually apply the interpolated
///    theme.
///  * [BoustroComponentThemeData], which describes the actual configuration of a theme.
class AnimatedBoustroComponentTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme.
  ///
  /// By default, the theme transition uses a linear curve. The [data] and
  /// [child] arguments must not be null.
  const AnimatedBoustroComponentTheme({
    Key? key,
    required this.data,
    Curve curve = Curves.linear,
    Duration duration = kThemeAnimationDuration,
    VoidCallback? onEnd,
    required this.child,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  /// The configuration of this theme.
  final BoustroComponentThemeData data;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _AnimatedBoustroComponentThemeState createState() =>
      _AnimatedBoustroComponentThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<BoustroComponentThemeData>('data', data));
  }
}

class _AnimatedBoustroComponentThemeState
    extends AnimatedWidgetBaseState<AnimatedBoustroComponentTheme> {
  BoustroComponentThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
            _data,
            widget.data,
            (dynamic value) => BoustroComponentThemeDataTween(
                begin: value as BoustroComponentThemeData))!
        as BoustroComponentThemeDataTween;
  }

  @override
  Widget build(BuildContext context) {
    return BoustroComponentTheme(
      data: _data!.evaluate(animation!),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<BoustroComponentThemeDataTween>(
        'data', _data,
        showName: false, defaultValue: null));
  }
}

/// Builder for [BoustroComponentThemeData].
///
/// Custom embeds or line modifiers are expected to define extension methods
/// to set any themeable values they require on this type.
class ComponentThemeBuilder {
  /// Create a component theme builder, optionally with a starting map of
  /// properties.
  ComponentThemeBuilder([Map<String, ThemeProperty<dynamic>>? props])
      : _props = props ?? {};

  final Map<String, ThemeProperty<dynamic>> _props;

  /// Get the value for [key].
  ThemeProperty<dynamic>? operator [](String key) => _props[key];

  /// Set the value for [key].
  void operator []=(String key, ThemeProperty<dynamic> value) =>
      _props[key] = value;

  /// Remove a property.
  void remove(String key) => _props.remove(key);

  /// Build the properties that have been set into a [BoustroComponentThemeData].
  BoustroComponentThemeData build() {
    return BoustroComponentThemeData(_props.build());
  }
}

/// A custom themeable property for user-provided embeds and line modifiers.
abstract class ThemeProperty<T> extends Equatable {
  /// Create a theme property with the provided value.
  const ThemeProperty(this.value);

  /// Value of the property.
  final T value;

  /// Linearly interpolate between [value] and [other].
  ThemeProperty<T> lerp(ThemeProperty<T> other, double t);

  @override
  List<Object?> get props => [value];
}

/// [ThemeProperty] implementation for values that cannot be interpolated.
///
/// Instead [lerp] will switch between this property and the provided other
/// property when t passes 0.5.
class UnlerpableThemeProperty<T> extends ThemeProperty<T> {
  /// Create an unlerpable theme property.
  const UnlerpableThemeProperty(T value) : super(value);

  @override
  ThemeProperty<T> lerp(ThemeProperty<T> other, double t) {
    return t < 0.5 ? this : other;
  }
}

/// [ThemeProperty] implementation for double values.
class DoubleThemeProperty extends ThemeProperty<double> {
  /// Create a double theme property.
  const DoubleThemeProperty(double value) : super(value);

  @override
  ThemeProperty<double> lerp(ThemeProperty<double> other, double t) {
    return DoubleThemeProperty(ui.lerpDouble(value, other.value, t)!);
  }
}

/// [ThemeProperty] implementation for [Color] values.
class ColorThemeProperty extends ThemeProperty<Color> {
  /// Create a color theme property.
  const ColorThemeProperty(Color value) : super(value);

  @override
  ThemeProperty<Color> lerp(ThemeProperty<Color> other, double t) {
    return ColorThemeProperty(Color.lerp(value, other.value, t)!);
  }
}
