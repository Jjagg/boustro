import 'package:boustro/boustro.dart';
import 'package:boustro/convert_delta.dart';
import 'package:flutter/painting.dart';

/// Attribute with a custom [TextStyle.fontWeight]. Defaults to
/// [FontWeight.bold].
final boldAttribute = _BoldAttribute();

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

/// Codec to convert [boldAttribute] to/from delta (see [DocumentDeltaConverter]).
final boldAttributeDeltaCodec = deltaBoolAttributeCodec('bold', boldAttribute);

/// Attribute with [TextStyle.fontStyle] set to [FontStyle.italic].
final italicAttribute = TextAttribute.simple(
  expandRules: SpanExpandRules.after(),
  debugName: 'italic',
  style: const TextStyle(fontStyle: FontStyle.italic),
);

/// Codec to convert [italicAttribute] to/from delta (see [DocumentDeltaConverter]).
final italicAttributeDeltaCodec = deltaBoolAttributeCodec(
  'italic',
  italicAttribute,
);

/// Attribute with [TextStyle.decoration] set to [TextDecoration.underline].
final underlineAttribute = TextAttribute.simple(
  expandRules: SpanExpandRules.after(),
  debugName: 'underline',
  style: const TextStyle(decoration: TextDecoration.underline),
);

/// Codec to convert [underlineAttribute] to/from delta (see [DocumentDeltaConverter]).
final underlineAttributeDeltaCodec = deltaBoolAttributeCodec(
  'underline',
  underlineAttribute,
);

/// Attribute with [TextStyle.decoration] set to [TextDecoration.lineThrough].
final strikethroughAttribute = TextAttribute.simple(
  expandRules: SpanExpandRules.after(),
  debugName: 'strikethrough',
  style: const TextStyle(decoration: TextDecoration.lineThrough),
);

/// Codec to convert [underlineAttribute] to/from delta (see [DocumentDeltaConverter]).
final strikethroughAttributeDeltaCodec = deltaBoolAttributeCodec(
  'strike',
  strikethroughAttribute,
);

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
