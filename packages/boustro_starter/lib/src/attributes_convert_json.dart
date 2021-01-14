import 'package:boustro/convert_json.dart';

import 'attributes.dart';

/// Codec to convert [boldAttribute] to/from JSON (see [DocumentJsonCodec]).
final bold = TextAttributeCodec.stateless(
  typeStr: 'bold',
  create: () => boldAttribute,
);

/// Codec to convert [italicAttribute] to/from JSON (see [DocumentJsonCodec]).
final italic = TextAttributeCodec.stateless(
  typeStr: 'italic',
  create: () => italicAttribute,
);

/// Codec to convert [underlineAttribute] to/from JSON (see [DocumentJsonCodec]).
final underline = TextAttributeCodec.stateless(
  typeStr: 'underline',
  create: () => underlineAttribute,
);

/// Codec to convert [underlineAttribute] to/from JSON (see [DocumentJsonCodec]).
final strikethrough = TextAttributeCodec.stateless(
  typeStr: 'strike',
  create: () => strikethroughAttribute,
);

/// Codec to convert [LinkAttribute] to/from JSON (see [DocumentJsonCodec]).
final link = TextAttributeCodec<LinkAttribute>.stateful(
  typeStr: 'link',
  encode: (attr) => attr.uri,
  decode: (uri) {
    if (uri is! String) {
      throw Exception('Expected string as data for link attribute.');
    }
    return LinkAttribute(uri);
  },
);
