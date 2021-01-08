import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/painting.dart';

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
  TextAttributeValue resolve(AttributeThemeData theme) =>
      const TextAttributeValue(
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
  TextAttributeValue resolve(AttributeThemeData theme) =>
      const TextAttributeValue(
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
  TextAttributeValue resolve(AttributeThemeData theme) =>
      const TextAttributeValue(
        debugName: 'strikethrough',
        style: TextStyle(decoration: TextDecoration.lineThrough),
      );
}

/// Attribute with [TextStyle.decoration] set to [TextDecoration.lineThrough].
const strikethroughAttribute = _StrikethroughAttribute();

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
  TextAttributeValue resolve(AttributeThemeData theme) {
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
  set boldFontWeight(FontWeight? value) {
    if (value == null) {
      remove('boldFontWeight');
    } else {
      this['boldFontWeight'] = value;
    }
  }

  /// Set the text style to apply to text with the [LinkAttribute] applied.
  set linkStyle(TextStyle? value) {
    if (value == null) {
      remove('linkStyle');
    } else {
      this['linkStyle'] = value;
    }
  }

  // FIXME linkOnTap should take a BuildContext

  /// onTap gesture handler to use for text with the [LinkAttribute] applied.
  set linkOnTap(void Function(String)? value) {
    if (value == null) {
      remove('linkOnTap');
    } else {
      this['linkOnTap'] = value;
    }
  }
}
