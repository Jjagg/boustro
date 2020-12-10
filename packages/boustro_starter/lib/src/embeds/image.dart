import 'package:boustro/boustro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ImageEmbed extends ParagraphEmbedBuilder {
  @override
  String get key => 'image';

  @override
  Widget buildEmbed(
    BoustroScope scope,
    BoustroParagraphEmbed embed, [
    FocusNode? focusNode,
  ]) {
    return _ImageEmbed(
      scope: scope,
      embed: embed,
      focusNode: focusNode,
    );
  }
}

class _ImageEmbed extends StatelessWidget {
  _ImageEmbed({
    required this.scope,
    required this.embed,
    required this.focusNode,
  });

  BoustroScope scope;
  BoustroParagraphEmbed embed;
  FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!scope.editable) {
      return _buildContent(hasFocus: false);
    }

    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final hasFocus = focusNode.hasFocus;
          return GestureDetector(
            onTap: () {
              if (hasFocus) {
                focusNode.unfocus();
              } else {
                focusNode.requestFocus();
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildContent(
                hasFocus: hasFocus,
                overlay: !hasFocus
                    ? []
                    : [
                        Center(
                          child: _buildButton(
                            icon: Icons.edit,
                            onPressed: () {},
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildButton(
                            icon: Icons.close,
                            onPressed: () {},
                          ),
                        ),
                      ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContent({required bool hasFocus, List<Widget> overlay = const []}) {
    Widget image = Image(
      image: embed.value as ImageProvider,
      fit: BoxFit.contain,
    );
    if (overlay.isNotEmpty) {
      image = Stack(
        fit: StackFit.expand,
        children: [image, ...overlay],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Container(
        //child: image,
        decoration: BoxDecoration(
            color: hasFocus ? Colors.red : Colors.brown.withOpacity(0.2),
            image: DecorationImage(
              image: embed.value as ImageProvider,
              fit: BoxFit.contain,
            )),
      ),
    );
  }
}
