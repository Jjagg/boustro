import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import 'theme.dart';

/// Encapsulates boustro configuration.
///
/// This is just for convenience, to flatten the inherited widgets that
/// configure boustro's behavior and look.
@immutable
class BoustroConfig extends StatelessWidget {
  /// Create a boustro configuration.
  const BoustroConfig({
    Key? key,
    this.boustroTheme,
    this.componentConfigData,
    this.attributeTheme,
    this.themeCurve,
    this.themeDuration,
    this.animateTheme = true,
    required this.builder,
  }) : super(key: key);

  /// Theme of boustro widgets.
  final BoustroThemeData? boustroTheme;

  /// Curve for the animation of the themes.
  final Curve? themeCurve;

  /// Duration for the animation of the themes.
  final Duration? themeDuration;

  /// Configuration of boustro components.
  final BoustroComponentConfigData? componentConfigData;

  /// Theming for text attributes.
  final AttributeThemeData? attributeTheme;

  /// Indicates if the themes should animate when they change.
  final bool animateTheme;

  /// Child builder of this widget.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    Widget widget = Builder(builder: builder);

    if (attributeTheme != null) {
      widget = AttributeTheme(data: attributeTheme!, child: widget);
    }

    if (componentConfigData != null) {
      widget = animateTheme
          ? AnimatedBoustroComponentConfig(
              data: componentConfigData!,
              curve: themeCurve ?? Curves.linear,
              duration: themeDuration ?? kThemeAnimationDuration,
              child: widget,
            )
          : BoustroComponentConfig(
              data: componentConfigData!,
              child: widget,
            );
    }

    if (boustroTheme != null) {
      widget = animateTheme
          ? AnimatedBoustroTheme(
              data: boustroTheme!,
              curve: themeCurve ?? Curves.linear,
              duration: themeDuration ?? kThemeAnimationDuration,
              child: widget,
            )
          : BoustroTheme(
              data: boustroTheme!,
              child: widget,
            );
    }

    return widget;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoustroThemeData?>(
        'boustroTheme', boustroTheme,
        defaultValue: null));
    properties.add(DiagnosticsProperty<BoustroComponentConfigData?>(
        'componentConfigData', componentConfigData,
        defaultValue: null));
    properties.add(DiagnosticsProperty<AttributeThemeData?>(
        'attributeTheme', attributeTheme,
        defaultValue: null));
    properties.add(ObjectFlagProperty.has('builder', builder));
    properties.add(DiagnosticsProperty<Curve?>('themeCurve', themeCurve));
    properties
        .add(DiagnosticsProperty<Duration?>('themeDuration', themeDuration));
    properties.add(FlagProperty('animateTheme',
        value: animateTheme, ifTrue: 'animated', showName: true));
  }
}
