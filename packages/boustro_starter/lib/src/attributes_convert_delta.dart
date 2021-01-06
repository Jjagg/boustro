import 'package:boustro/convert_delta.dart';

import 'attributes.dart';

/// Codec to convert [boldAttribute] to/from delta (see [DocumentDeltaConverter]).
final boldCodec = deltaBoolAttributeCodec('bold', boldAttribute);

/// Codec to convert [italicAttribute] to/from delta (see [DocumentDeltaConverter]).
final italicCodec = deltaBoolAttributeCodec(
  'italic',
  italicAttribute,
);

/// Codec to convert [underlineAttribute] to/from delta (see [DocumentDeltaConverter]).
final underlineCodec = deltaBoolAttributeCodec(
  'underline',
  underlineAttribute,
);

/// Codec to convert [underlineAttribute] to/from delta (see [DocumentDeltaConverter]).
final strikethroughCodec = deltaBoolAttributeCodec(
  'strike',
  strikethroughAttribute,
);
