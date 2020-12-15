import 'package:boustro/boustro.dart';
import 'package:boustro/convert_delta.dart';
import 'package:flutter/painting.dart';

/// Attribute with [TextStyle.fontWeight] set to [FontWeight.bold].
final boldAttribute = TextAttribute.simple(
  debugName: 'bold',
  style: const TextStyle(fontWeight: FontWeight.bold),
);

/// Codec to convert [boldAttribute] to/from delta (see [BoustroDocumentDeltaConverter]).
final boldAttributeDeltaCodec = deltaBoolAttributeCodec(
  'bold',
  boldAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);

/// Attribute with [TextStyle.fontStyle] set to [FontStyle.italic].
final italicAttribute = TextAttribute.simple(
  debugName: 'italic',
  style: const TextStyle(fontStyle: FontStyle.italic),
);

/// Codec to convert [italicAttribute] to/from delta (see [BoustroDocumentDeltaConverter]).
final italicAttributeDeltaCodec = deltaBoolAttributeCodec(
  'italic',
  italicAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);

/// Attribute with [TextStyle.decoration] set to [TextDecoration.underline].
final underlineAttribute = TextAttribute.simple(
  debugName: 'underline',
  style: const TextStyle(decoration: TextDecoration.underline),
);

/// Codec to convert [underlineAttribute] to/from delta (see [BoustroDocumentDeltaConverter]).
final underlineAttributeDeltaCodec = deltaBoolAttributeCodec(
  'underline',
  underlineAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);
