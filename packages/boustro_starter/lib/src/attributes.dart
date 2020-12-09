import 'package:boustro/boustro.dart';
import 'package:boustro/convert_delta.dart';
import 'package:flutter/painting.dart';

const boldAttribute = TextAttribute(
  debugName: 'bold',
  style: TextStyle(fontWeight: FontWeight.bold),
);
final boldAttributeDeltaCodec = deltaBoolAttributeCodec(
  'bold',
  boldAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);

const italicAttribute = TextAttribute(
  debugName: 'italic',
  style: TextStyle(fontStyle: FontStyle.italic),
);
final italicAttributeDeltaCodec = deltaBoolAttributeCodec(
  'italic',
  italicAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);

const underlineAttribute = TextAttribute(
  debugName: 'underline',
  style: TextStyle(decoration: TextDecoration.underline),
);
final underlineAttributeDeltaCodec = deltaBoolAttributeCodec(
  'underline',
  underlineAttribute,
  InsertBehavior.exclusive,
  InsertBehavior.inclusive,
);
