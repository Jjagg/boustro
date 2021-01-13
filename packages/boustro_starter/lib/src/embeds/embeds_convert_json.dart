import 'dart:io';

import 'package:boustro/convert_json.dart';
import 'package:flutter/widgets.dart';

import 'image_embed.dart';

/// Codec to convert [ImageEmbed] to/from JSON (see [DocumentJsonCodec]).
final image = ParagraphEmbedCodec<ImageEmbed>.stateful(
  typeStr: 'image',
  encode: (e) {
    final img = e.image;
    if (img is FileImage) {
      return img.file.absolute.uri.toString();
    }
    if (img is NetworkImage) {
      return img.url;
    }

    throw UnimplementedError(
        'Only FileImage and NetworkImage serializers are implemented at this time.');
  },
  decode: (e) {
    if (e is! String) {
      throw Exception('Expected string as data for image embed.');
    }

    final ImageProvider image;
    if (e.startsWith('file://')) {
      image = FileImage(File(e.substring('file://'.length)));
    } else {
      image = NetworkImage(e);
    }

    return ImageEmbed(image);
  },
);
