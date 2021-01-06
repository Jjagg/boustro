import 'package:boustro/boustro.dart';
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

/// Themeable property getter extensions for the attributes in this library.
extension AttributeGetters on AttributeThemeData {
  /// Font weight for text with [boldAttribute] applied.
  FontWeight? get boldFontWeight => get<FontWeight>('boldFontWeight');
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
}
