import 'package:boustro/boustro.dart';
import 'package:flutter/widgets.dart';

final imageEmbed = ParagraphEmbedHandler(
  'image',
  (scope, embed, [focusNode]) {
    return GestureDetector(
      onTap: focusNode == null
          ? null
          : () {
              if (focusNode.hasPrimaryFocus) {
                focusNode.unfocus();
              } else {
                focusNode.requestFocus();
              }
            },
      child: Focus(
        focusNode: focusNode,
        child: Padding(
          padding: EdgeInsets.all(
              (focusNode?.hasPrimaryFocus ?? false) ? 8.0 : 20.0),
          child: Image.network(embed.value as String),
        ),
      ),
    );
  },
);
