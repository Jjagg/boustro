import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

class _BoldAttribute extends ThemedTextAttribute {
  _BoldAttribute() : super(debugName: 'bold');

  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextStyle? getStyle(AttributeThemeData theme) {
    final weight = theme.boldFontWeight ?? FontWeight.bold;
    return TextStyle(fontWeight: weight);
  }
}

/// Attribute with a custom [TextStyle.fontWeight]. Defaults to
/// [FontWeight.bold].
final boldAttribute = _BoldAttribute();

class _ItalicAttribute extends TextAttribute {
  const _ItalicAttribute();

  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextAttributeValue resolve(BuildContext context) => const TextAttributeValue(
        debugName: 'italic',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
}

/// Attribute with [TextStyle.fontStyle] set to [FontStyle.italic].
const italicAttribute = _ItalicAttribute();

class _UnderlineAttribute extends TextAttribute {
  const _UnderlineAttribute();

  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextAttributeValue resolve(BuildContext context) => const TextAttributeValue(
        debugName: 'underline',
        style: TextStyle(decoration: TextDecoration.underline),
      );
}

/// Attribute with [TextStyle.decoration] set to [TextDecoration.underline].
const underlineAttribute = _UnderlineAttribute();

class _StrikethroughAttribute extends TextAttribute {
  const _StrikethroughAttribute();

  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextAttributeValue resolve(BuildContext context) => const TextAttributeValue(
        debugName: 'strikethrough',
        style: TextStyle(decoration: TextDecoration.lineThrough),
      );
}

/// Attribute with [TextStyle.decoration] set to [TextDecoration.lineThrough].
const strikethroughAttribute = _StrikethroughAttribute();

/// Attribute for headings. Intended to be used as a line style.
///
/// Uses the common HTML-style headings with levels 1-6
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
class HeadingAttribute extends TextAttribute with EquatableMixin {
  /// Create a heading attribute with a level between 1 and 6 (inclusive).
  const HeadingAttribute(this.level)
      : assert(level >= 1 && level <= 6,
            'Level should be between 1 and 6 (inclusive).');

  /// Level of the heading.
  final int level;

  @override
  SpanExpandRules get expandRules => SpanExpandRules.fixed();

  @override
  List<Object?> get props => [level];

  @override
  TextAttributeValue resolve(BuildContext context) {
    final attrTheme = AttributeTheme.of(context);
    final theme = Theme.of(context);
    final TextStyle? style;
    switch (level) {
      case 1:
        style = attrTheme.headingStyle1 ?? theme.textTheme.headline4;
        break;
      case 2:
        style = attrTheme.headingStyle2 ?? theme.textTheme.headline5;
        break;
      case 3:
        style = attrTheme.headingStyle3 ?? theme.textTheme.headline6;
        break;
      case 4:
        style = attrTheme.headingStyle4 ?? theme.textTheme.subtitle1;
        break;
      case 5:
        style = attrTheme.headingStyle5 ?? theme.textTheme.subtitle1;
        break;
      case 6:
        style = attrTheme.headingStyle6 ?? theme.textTheme.subtitle1;
        break;
      default:
        throw Exception('Invalid heading level "$level".');
    }

    return TextAttributeValue(style: style);
  }
}

/// Attribute that turns the spanned text into a hyperlink based on some URI.
class LinkAttribute extends TextAttribute with EquatableMixin {
  /// Create a link attribute with a destination uri.
  const LinkAttribute(this.uri);

  /// Uri destination of the link.
  final String uri;

  @override
  SpanExpandRules get expandRules =>
      SpanExpandRules(ExpandRule.exclusive, ExpandRule.exclusive);

  @override
  TextAttributeValue resolve(BuildContext context) {
    final theme = AttributeTheme.of(context);
    final style = theme.linkStyle;
    final onTap = theme.linkOnTap;
    if (kDebugMode && onTap == null) {
      // ignore: avoid_print
      print(
          'WARNING: onTap handler for LinkAttribute not set on AttributeTheme.');
    }

    return TextAttributeValue(
      debugName: 'link<$uri>',
      style: style,
      onTap: onTap == null ? null : () => onTap(uri),
    );
  }

  @override
  String toString() {
    return 'LinkAttribute<$uri>';
  }

  @override
  List<Object?> get props => [uri];
}

/// Themeable property getter extensions for the attributes in this library.
extension AttributeGetters on AttributeThemeData {
  /// Font weight for text with [boldAttribute] applied.
  FontWeight? get boldFontWeight => get<FontWeight>('boldFontWeight');

  /// Style of [HeadingAttribute] with level 1.
  TextStyle? get headingStyle1 => get<TextStyle>('headingStyle1');

  /// Style of [HeadingAttribute] with level 2.
  TextStyle? get headingStyle2 => get<TextStyle>('headingStyle2');

  /// Style of [HeadingAttribute] with level 3.
  TextStyle? get headingStyle3 => get<TextStyle>('headingStyle3');

  /// Style of [HeadingAttribute] with level 4.
  TextStyle? get headingStyle4 => get<TextStyle>('headingStyle4');

  /// Style of [HeadingAttribute] with level 5.
  TextStyle? get headingStyle5 => get<TextStyle>('headingStyle5');

  /// Style of [HeadingAttribute] with level 6.
  TextStyle? get headingStyle6 => get<TextStyle>('headingStyle6');

  /// Text style to apply to text with the [LinkAttribute] applied.
  TextStyle? get linkStyle => get<TextStyle>('linkStyle');

  /// onTap gesture handler to use for text with the [LinkAttribute] applied.
  void Function(String)? get linkOnTap =>
      get<void Function(String)>('linkOnTap');
}

/// Themeable property setter extensions for the attributes in this library.
///
/// See the getters in [AttributeGetters] for more information on the properties.
extension AttributeSetters on AttributeThemeBuilder {
  /// Set the font weight for text with [boldAttribute] applied.
  set boldFontWeight(FontWeight? value) => this['boldFontWeight'] = value;

  /// Set the style of [HeadingAttribute] with level 1.
  set headingStyle1(TextStyle? value) => this['headingStyle1'] = value;

  /// Set the style of [HeadingAttribute] with level 2.
  set headingStyle2(TextStyle? value) => this['headingStyle2'] = value;

  /// Set the style of [HeadingAttribute] with level 3.
  set headingStyle3(TextStyle? value) => this['headingStyle3'] = value;

  /// Set the style of [HeadingAttribute] with level 4.
  set headingStyle4(TextStyle? value) => this['headingStyle4'] = value;

  /// Set the style of [HeadingAttribute] with level 5.
  set headingStyle5(TextStyle? value) => this['headingStyle5'] = value;

  /// Set the style of [HeadingAttribute] with level 6.
  set headingStyle6(TextStyle? value) => this['headingStyle6'] = value;

  /// Set the text style to apply to text with the [LinkAttribute] applied.
  set linkStyle(TextStyle? value) => this['linkStyle'] = value;

  // FIXME linkOnTap should take a BuildContext

  /// onTap gesture handler to use for text with the [LinkAttribute] applied.
  set linkOnTap(void Function(String)? value) => this['linkOnTap'] = value;
}
