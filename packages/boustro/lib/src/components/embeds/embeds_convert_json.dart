import 'dart:io';

import 'package:boustro/convert_json.dart';
import 'package:flutter/widgets.dart';

import 'image_embed.dart';

/// Codec to convert [ImageEmbed] to/from JSON (see [DocumentJsonCodec]).
final image = ParagraphEmbedCodec<ImageEmbed>.stateful(
  typeStr: 'image',
  encode: (e) {
    final img = e.image;
    final String imgStr;
    if (img is FileImage) {
      imgStr = img.file.absolute.uri.toString();
    } else if (img is NetworkImage) {
      imgStr = img.url;
    } else {
      throw UnimplementedError(
          'Only FileImage and NetworkImage serializers are implemented at this time.');
    }

    return {
      'image': imgStr,
      if (e.alt != null) 'alt': e.alt,
    };
  },
  decode: (e) {
    if (e is! Map<String, dynamic> || !e.keys.contains('image')) {
      throw const FormatException('The image field is required for images.');
    }

    final imageStr = e['image'] as String;

    final ImageProvider image;
    if (imageStr.startsWith('file://')) {
      image = FileImage(File(imageStr.substring('file://'.length)));
    } else {
      image = NetworkImage(imageStr);
    }

    final alt = e['alt'] as String?;

    return ImageEmbed(image: image, alt: alt);
  },
);
