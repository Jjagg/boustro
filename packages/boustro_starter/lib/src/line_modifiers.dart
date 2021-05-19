import 'dart:ui';

import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// TODO This was designed to mimic Android's paragraph styles, but with
// composition, but I don't think it's that useful to have this granularity.
// Should maybe remove these?

/// Base class to compose in a [LineModifier] to order some widget
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
  })  : paddingLeft = paddingLeft ?? padding ?? 0,
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
  })  : paddingLeft = paddingLeft ?? padding ?? 0,
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
    var textStyle = theme.textTheme.subtitle1;
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
const bulletListModifier = _BulletListModifier();

/// Paragraph modifier that puts a bullet before the text.
class _BulletListModifier extends LineModifier with EquatableMixin {
  /// Create a bullet list modifier.
  const _BulletListModifier();

  @override
  Widget modify(
    BuildContext context,
    Widget child,
  ) {
    return LeadingTextModifier(
      padding: 8,
      text: '\u2022',
      child: child,
    );
  }

  @override
  List<Object?> get props => const [];
}

/// Paragraph modifier that puts a number before the text.
class NumberedListModifier extends LineModifier {
  /// Create a numbered list modifier.
  const NumberedListModifier(this.number);

  /// The number to display.
  final int number;

  @override
  Widget modify(
    BuildContext context,
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
}

/// [HeadingModifier] with level 1.
const heading1Modifier = HeadingModifier(1);

/// [HeadingModifier] with level 2.
const heading2Modifier = HeadingModifier(2);

/// [HeadingModifier] with level 3.
const heading3Modifier = HeadingModifier(3);

/// [HeadingModifier] with level 4.
const heading4Modifier = HeadingModifier(4);

/// [HeadingModifier] with level 5.
const heading5Modifier = HeadingModifier(5);

/// [HeadingModifier] with level 6.
const heading6Modifier = HeadingModifier(6);

/// Modifier for headings. Intended to be used as a line style.
///
/// Uses the common HTML-style for headings with levels 1-6
/// (inclusive).
///
/// The default style for headings is:
///
/// 1. [TextTheme.headline4]
/// 2. [TextTheme.headline5]
/// 3. [TextTheme.headline6]
/// 4. [TextTheme.subtitle1]
/// 5. [TextTheme.subtitle1]
/// 6. [TextTheme.subtitle1]
class HeadingModifier extends LineModifier with EquatableMixin {
  /// Create a heading attribute with a level between 1 and 6 (inclusive).
  const HeadingModifier(this.level)
      : assert(level >= 1 && level <= 6,
            'Level should be between 1 and 6 (inclusive).');

  /// Level of the heading.
  final int level;

  @override
  List<Object?> get props => [level];

  @override
  Widget modify(BuildContext context, Widget child) {
    final ctheme = BoustroComponentConfig.of(context);
    final theme = Theme.of(context);
    final TextStyle? style;
    switch (level) {
      case 1:
        style = ctheme.headingStyle1 ?? theme.textTheme.headline4;
        break;
      case 2:
        style = ctheme.headingStyle2 ?? theme.textTheme.headline5;
        break;
      case 3:
        style = ctheme.headingStyle3 ?? theme.textTheme.headline6;
        break;
      case 4:
        style = ctheme.headingStyle4 ?? theme.textTheme.subtitle1;
        break;
      case 5:
        style = ctheme.headingStyle5 ?? theme.textTheme.subtitle1;
        break;
      case 6:
        style = ctheme.headingStyle6 ?? theme.textTheme.subtitle1;
        break;
      default:
        throw Exception('Invalid heading level "$level".');
    }
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          subtitle1: style,
        ),
      ),
      child: child,
    );
  }
}

/// Themeable property getter extensions for the attributes in this library.
extension LineModGetters on BoustroComponentConfigData {
  /// Style of [HeadingModifier] with level 1.
  TextStyle? get headingStyle1 => get<TextStyle>('headingStyle1');

  /// Style of [HeadingModifier] with level 2.
  TextStyle? get headingStyle2 => get<TextStyle>('headingStyle2');

  /// Style of [HeadingModifier] with level 3.
  TextStyle? get headingStyle3 => get<TextStyle>('headingStyle3');

  /// Style of [HeadingModifier] with level 4.
  TextStyle? get headingStyle4 => get<TextStyle>('headingStyle4');

  /// Style of [HeadingModifier] with level 5.
  TextStyle? get headingStyle5 => get<TextStyle>('headingStyle5');

  /// Style of [HeadingModifier] with level 6.
  TextStyle? get headingStyle6 => get<TextStyle>('headingStyle6');
}

/// Themeable property setter extensions for the attributes in this library.
///
/// See the getters in [LineModGetters] for more information on the properties.
extension LineModSetters on BoustroComponentConfigBuilder {
  /// Set the style of [HeadingModifier] with level 1.
  set headingStyle1(TextStyle? value) =>
      this['headingStyle1'] = TextStyleThemeProperty.maybe(value);

  /// Set the style of [HeadingModifier] with level 2.
  set headingStyle2(TextStyle? value) =>
      this['headingStyle2'] = TextStyleThemeProperty.maybe(value);

  /// Set the style of [HeadingModifier] with level 3.
  set headingStyle3(TextStyle? value) =>
      this['headingStyle3'] = TextStyleThemeProperty.maybe(value);

  /// Set the style of [HeadingModifier] with level 4.
  set headingStyle4(TextStyle? value) =>
      this['headingStyle4'] = TextStyleThemeProperty.maybe(value);

  /// Set the style of [HeadingModifier] with level 5.
  set headingStyle5(TextStyle? value) =>
      this['headingStyle5'] = TextStyleThemeProperty.maybe(value);

  /// Set the style of [HeadingModifier] with level 6.
  set headingStyle6(TextStyle? value) =>
      this['headingStyle6'] = TextStyleThemeProperty.maybe(value);
}
