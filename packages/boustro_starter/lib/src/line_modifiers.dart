import 'package:boustro/boustro.dart';
import 'package:flutter/material.dart';

class LeadingMarginModifier extends StatelessWidget {
  const LeadingMarginModifier({
    Key? key,
    required this.leading,
    required this.child,
  }) : super(key: key);

  final Widget leading;
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

class TextAlignedLeadingMarginModifier extends StatelessWidget {
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

  final double paddingLeft;
  final double paddingRight;
  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    // Apply vertical line padding to align with the text.
    final padding = btheme.linePadding.resolve(Directionality.of(context));
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
}

class CharacterLeadingMarginModifier extends StatelessWidget {
  const CharacterLeadingMarginModifier({
    Key? key,
    this.style,
    double? padding,
    double? paddingLeft,
    double? paddingRight,
    required this.character,
    required this.child,
  })   : paddingLeft = paddingLeft ?? padding ?? 0,
        paddingRight = paddingRight ?? padding ?? 0,
        super(key: key);

  final TextStyle? style;
  final double paddingLeft;
  final double paddingRight;
  final String character;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var textStyle = style;
    if (textStyle == null) {
      final theme = Theme.of(context);
      textStyle = theme.primaryTextTheme.subtitle1;
    }
    return TextAlignedLeadingMarginModifier(
      paddingLeft: paddingLeft,
      paddingRight: paddingRight,
      leading: Text(character, style: textStyle),
      child: child,
    );
  }
}
