import 'dart:io';

import 'package:boustro/boustro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Embed that presents an image.
///
/// Its value should be an [ImageProvider].
///
/// While editing, tapping the image will focus it.
class ImageEmbed extends ParagraphEmbed {
  /// Create an image embed.
  const ImageEmbed(this.image);

  /// Image that this embed displays.
  final ImageProvider image;

  @override
  Widget build({
    required BoustroScope scope,
    FocusNode? focusNode,
  }) {
    return _ImageEmbed(
      image: image,
      scope: scope,
      focusNode: focusNode,
    );
  }
}

class _ImageEmbed extends StatelessWidget {
  const _ImageEmbed({
    required this.image,
    required this.scope,
    required this.focusNode,
  });

  final ImageProvider image;
  final BoustroScope scope;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final ctheme = BoustroComponentConfig.of(context);
    if (!scope.isEditable) {
      return _buildContent(context, ctheme, _center);
    }

    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final child = _buildContent(
            context,
            ctheme,
            _buildOverlay,
          );

          return GestureDetector(
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

  Widget _center(
    BuildContext context,
    BoustroComponentConfigData ctheme,
    Widget child,
  ) {
    return Center(child: child);
  }

  Widget _buildOverlay(
    BuildContext context,
    BoustroComponentConfigData ctheme,
    Widget child,
  ) {
    final hasFocus = Focus.of(context).hasFocus;
    final pickImg = ctheme.imagePickImage;
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
                  if (pickImg != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildButton(
                          context: context,
                          icon: Icons.edit,
                          onPressed: () {
                            // TODO edit image
                          },
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
    BuildContext context,
    BoustroComponentConfigData ctheme,
    Widget Function(BuildContext context, BoustroComponentConfigData ctheme,
            Widget child)
        imageWrapper,
  ) {
    final maxHeight = ctheme.imageMaxHeight ?? 450;

    final sideColor = ctheme.imageSideColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.deepPurple.shade900.withOpacity(0.2)
            : Colors.brown.withOpacity(0.2));

    Widget widget = Image(
      image: image,
      fit: BoxFit.contain,
    );

    widget = imageWrapper(context, ctheme, widget);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        color: sideColor,
        child: widget,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ImageProvider>('image', image))
      ..add(DiagnosticsProperty<BoustroScope>('scope', scope))
      ..add(DiagnosticsProperty<FocusNode?>('focusNode', focusNode));
  }
}

/// Signature for function used to pick an image.
typedef PickImage = File? Function();

/// Themeable property getter extensions for [ImageEmbed].
extension ImageEmbedTheme on BoustroComponentConfigData {
  /// The maximum height of an image in logical pixels.
  ///
  /// Higher images will be resized, keeping their aspect ratio.
  /// The color in [imageSideColor] will be painted to the sides of the image.
  double? get imageMaxHeight => get<double>('imageMaxHeight');

  /// Color painted to the side of the image if it does not cover the full
  /// width available to it.
  Color? get imageSideColor => get<Color>('imageSideColor');

  /// Get the closure that's called when an image should be picked.
  PickImage? get imagePickImage => get<PickImage>('imagePickImage');
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

  /// Set the color painted to the side of the image.
  set imageSideColor(Color? value) {
    if (value == null) {
      remove('imageSideColor');
    } else {
      this['imageSideColor'] = ColorThemeProperty(value);
    }
  }

  /// Set the closure that's called when an image should be picked.
  set imagePickImage(PickImage? value) {
    if (value == null) {
      remove('imagePickImage');
    } else {
      this['imagePickImage'] = UnlerpableThemeProperty<PickImage>(value);
    }
  }
}
