import 'package:boustro/boustro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'embed_gesture_handler.dart';

/// Embed that presents an image.
///
/// Its type is 'image' and value should be an [ImageProvider].
///
/// Looks for an [EmbedGestureHandler]<ImageEmbed> to handle gestures.
/// If one is missing, default gesture handling will be added:
///
/// * While editing, tapping the image will toggle focus.
class ImageEmbed extends ParagraphEmbedBuilder {
  @override
  String get type => 'image';

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
  const _ImageEmbed({
    required this.scope,
    required this.embed,
    required this.focusNode,
  });

  final BoustroScope scope;
  final BoustroParagraphEmbed embed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (!scope.isEditable) {
      return _buildContent(context, imageWrapper: _center);
    }

    final gestureHandler = context
        .dependOnInheritedWidgetOfExactType<EmbedGestureHandler<ImageEmbed>>();

    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final child = _buildContent(
            context,
            imageWrapper: _buildOverlay,
          );

          return gestureHandler?.toDetector(child: child) ??
              GestureDetector(
                onTap: () {
                  if (!focusNode.hasFocus) {
                    focusNode.requestFocus();
                  }
                },
                child: child,
              );
        },
      ),
    );
  }

  Widget _center(BuildContext context, Widget child) => Center(child: child);

  Widget _buildOverlay(BuildContext context, Widget child) {
    final hasFocus = Focus.of(context).hasFocus;
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: AnimatedCrossFade(
              crossFadeState: hasFocus
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 800),
              firstChild: const SizedBox(),
              secondChild: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildButton(
                        context: context,
                        icon: Icons.edit,
                        onPressed: () {},
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildButton(
                        context: context,
                        icon: Icons.close,
                        onPressed: () {
                          scope.controller!.removeCurrentParagraph();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Widget Function(BuildContext context, Widget child) imageWrapper,
  }) {
    final ctheme = BoustroComponentTheme.of(context);
    final maxHeight = ctheme.imageMaxHeight ?? 450;

    final sideColor = ctheme.imageSideColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.deepPurple.shade900.withOpacity(0.2)
            : Colors.brown.withOpacity(0.2));

    Widget image = Image(
      image: embed.value as ImageProvider,
      fit: BoxFit.contain,
    );

    image = imageWrapper(context, image);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        color: sideColor,
        child: image,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<BoustroScope>('scope', scope))
      ..add(DiagnosticsProperty<BoustroParagraphEmbed>('embed', embed))
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode));
  }
}

/// Themeable property getter extensions for [ImageEmbed].
extension ImageEmbedTheme on BoustroComponentThemeData {
  /// The maximum height of an image in logical pixels.
  ///
  /// Higher images will be resized, keeping their aspect ratio.
  /// The color in [imageSideColor] will be painted to the sides of the image.
  double? get imageMaxHeight => get<double>('imageMaxHeight');

  /// Color painted to the side of the image if it does not cover the full
  /// width available to it.
  Color? get imageSideColor => get('imageSideColor');
}

/// Themeable property setter extensions for [ImageEmbed].
///
/// See the getters in [ImageEmbedTheme] for more information on the properties.
extension ImageEmbedThemeSet on ComponentThemeBuilder {
  /// Set the max height for an image embed.
  set imageMaxHeight(double? value) {
    if (value == null) {
      remove('imageMaxHeight');
    } else {
      this['imageMaxHeight'] = DoubleThemeProperty(value);
    }
  }

  set imageSideColor(Color? value) {
    if (value == null) {
      remove('imageSideColor');
    } else {
      this['imageSideColor'] = ColorThemeProperty(value);
    }
  }
}
