import 'package:boustro/convert_json.dart';

import 'line_modifiers.dart';

/// Codec to convert [bulletListModifier] to/from JSON (see [DocumentJsonCodec]).
final bulletList = LineModifierCodec.stateless(
  typeStr: 'bulletList',
  create: () => bulletListModifier,
);
