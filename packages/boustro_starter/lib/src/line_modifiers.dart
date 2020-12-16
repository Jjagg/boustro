import 'dart:ui';

import 'package:boustro/boustro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// TODO This was designed to mimic Android's paragraph styles, but with
// composition, but I don't think it's that useful to have this granularity.
// Should maybe remove these?

/// Base class to compose in a [LineParagraphModifier] to order some widget
/// before the text widget.
class LeadingMarginModifier extends StatelessWidget {
  /// Constant constructor for a leading margin modifier.
  const LeadingMarginModifier({
    Key? key,
    required this.leading,
    required this.child,
  }) : super(key: key);

  /// Widget to display before [child].
  final Widget leading;

  /// The text widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        Expanded(child: child),
      ],
    );
  }
}

/// Wraps a [LeadingMarginModifier] leading widget with the same padding that
/// is applied to the text. Use this to align [leading] with the text widget.
class TextAlignedLeadingMarginModifier extends StatelessWidget {
  /// [paddingLeft] and [paddingRight] will use [padding] if they're null
  /// 0 if [padding] is also null.
  const TextAlignedLeadingMarginModifier({
    Key? key,
    double? padding,
    double? paddingLeft,
    double? paddingRight,
    required this.leading,
    required this.child,
  })   : paddingLeft = paddingLeft ?? padding ?? 0,
        paddingRight = paddingRight ?? padding ?? 0,
        super(key: key);

  /// Padding to the left of [leading].
  final double paddingLeft;

  /// Padding to the right of [leading].
  final double paddingRight;

  /// Widget to display before [child].
  final Widget leading;

  /// The text widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    // Apply vertical line padding to align with the text.
    final padding = (btheme.linePadding ??
            BoustroThemeData.fallbackForContext(context).linePadding!)
        .resolve(Directionality.of(context));
    return LeadingMarginModifier(
        leading: Padding(
            padding: EdgeInsets.only(
              top: padding.top,
              bottom: padding.bottom,
              left: paddingLeft,
              right: paddingRight,
            ),
            child: leading),
        child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('paddingLeft', paddingLeft, defaultValue: 0))
      ..add(DoubleProperty('paddingRight', paddingRight, defaultValue: 0))
      ..add(DiagnosticsProperty<Widget>('leading', leading))
      ..add(DiagnosticsProperty<Widget>('child', child));
  }
}

/// A [TextAlignedLeadingMarginModifier] that has [Text] as its
/// leading widget.
class LeadingTextModifier extends StatelessWidget {
  /// [paddingLeft] and [paddingRight] will use [padding] if they're null
  /// 0 if [padding] is also null.
  const LeadingTextModifier({
    Key? key,
    this.style,
    double? padding,
    double? paddingLeft,
    double? paddingRight,
    required this.text,
    required this.child,
  })   : paddingLeft = paddingLeft ?? padding ?? 0,
        paddingRight = paddingRight ?? padding ?? 0,
        super(key: key);

  /// Style for the text. Will be merged with [TextTheme.subtitle1] from
  /// [Theme].
  final TextStyle? style;

  /// Padding to the left of the text widget with [text].
  final double paddingLeft;

  /// Padding to the right of the text widget with [text].
  final double paddingRight;

  /// String to put in the leading [Text] widget.
  final String text;

  /// The boustro text widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var textStyle = theme.primaryTextTheme.subtitle1;
    if (style != null) {
      if (textStyle == null) {
        textStyle = style;
      } else {
        textStyle = textStyle.merge(style);
      }
    }

    return TextAlignedLeadingMarginModifier(
      paddingLeft: paddingLeft,
      paddingRight: paddingRight,
      leading: Text(text, style: textStyle),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle?>('style', style, defaultValue: null))
      ..add(DoubleProperty('paddingLeft', paddingLeft, defaultValue: 0))
      ..add(DoubleProperty('paddingRight', paddingRight, defaultValue: 0))
      ..add(StringProperty('text', text));
  }
}

/// Paragraph modifier that puts a bullet before the text.
class BulletListModifier extends LineParagraphModifier {
  /// Create a bullet list modifier.
  const BulletListModifier();

  @override
  Widget modify(
    BuildContext context,
    Map<String, Object> properties,
    Widget child,
  ) {
    return LeadingTextModifier(
      padding: 8,
      text: '\u2022',
      child: child,
    );
  }

  @override
  int get priority => 0;

  @override
  bool shouldBeApplied(Map<String, Object> properties) {
    return properties['list'] == 'bullet';
  }
}

/// Paragraph modifier that puts a number before the text.
class NumberedListModifier extends LineParagraphModifier {
  /// Create a numbered list modifier.
  const NumberedListModifier(this.number);

  /// The number to display.
  final int number;

  @override
  Widget modify(
    BuildContext context,
    Map<String, Object> properties,
    Widget child,
  ) {
    // TODO this probably need some work to align properly.
    return LeadingTextModifier(
      padding: 8,
      text: '$number.',
      style: const TextStyle(
        fontFeatures: [
          FontFeature.tabularFigures(),
        ],
      ),
      child: child,
    );
  }

  @override
  int get priority => 0;

  @override
  bool shouldBeApplied(Map<String, Object> properties) {
    return properties['list'] == 'numbered';
  }
}
