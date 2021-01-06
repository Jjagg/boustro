import 'package:boustro/convert_json.dart';

import 'attributes.dart';

/// Codec to convert [boldAttribute] to/from json (see [DocumentJsonCodec]).
final bold = TextAttributeCodec.stateless(
  typeStr: 'bold',
  create: () => boldAttribute,
);

/// Codec to convert [italicAttribute] to/from json (see [DocumentJsonCodec]).
final italic = TextAttributeCodec.stateless(
  typeStr: 'italic',
  create: () => italicAttribute,
);

/// Codec to convert [underlineAttribute] to/from json (see [DocumentJsonCodec]).
final underline = TextAttributeCodec.stateless(
  typeStr: 'underline',
  create: () => underlineAttribute,
);

/// Codec to convert [underlineAttribute] to/from json (see [DocumentJsonCodec]).
final strikethrough = TextAttributeCodec.stateless(
  typeStr: 'strike',
  create: () => strikethroughAttribute,
);
