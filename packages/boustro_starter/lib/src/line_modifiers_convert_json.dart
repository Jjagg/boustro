import 'package:boustro/convert_json.dart';

import 'line_modifiers.dart';

/// Codec to convert [bulletListModifier] to/from JSON (see [DocumentJsonCodec]).
final bulletList = LineModifierCodec.stateless(
  typeStr: 'bulletList',
  create: () => bulletListModifier,
);

/// Codec to convert [HeadingModifier] to/from JSON (see [DocumentJsonCodec]).
final heading = LineModifierCodec<HeadingModifier>.stateful(
  typeStr: 'heading',
  encode: (mod) => mod.level,
  decode: (level) {
    if (level is! int) {
      throw Exception('Expected integer as data for heading attribute.');
    }
    return HeadingModifier(level);
  },
);
