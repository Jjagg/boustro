import 'dart:io';

import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Embed that displays an image.
@immutable
class ImageEmbed extends ParagraphEmbed with EquatableMixin {
  /// Create an image embed.
  const ImageEmbed(this.image);

  /// Provider for the image.
  final ImageProvider image;

  @override
  Widget createView(BuildContext context) {
    return ImageEmbedView(image: image);
  }

  @override
  ParagraphEmbedController createController() {
    return ImageEmbedController(value: image);
  }

  @override
  List<Object?> get props => [image];
}

class _ImageWrapper extends StatelessWidget {
  const _ImageWrapper({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ctheme = BoustroComponentConfig.of(context);
    final maxHeight = ctheme.imageMaxHeight ?? 1000;

    final sideColor = ctheme.imageSideColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.deepPurple.shade900.withOpacity(0.2)
            : Colors.brown.withOpacity(0.2));

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      color: sideColor,
      child: child,
    );
  }
}

/// Widget for [ImageEmbed].
class ImageEmbedView extends StatelessWidget {
  /// Create an image embed view.
  const ImageEmbedView({Key? key, required this.image}) : super(key: key);

  /// Provider for the image.
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return _ImageWrapper(
      child: Center(
        heightFactor: 1,
        child: Image(
          image: image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider<Object>>('image', image));
  }
}

/// Editor for [ImageEmbed].
///
/// While editing, tapping the image will focus it.
class ImageEmbedEditor extends StatelessWidget {
  /// Create an image embed.
  const ImageEmbedEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  /// Controller that manages the current image provider.
  final ImageEmbedController controller;

  /// Focus node that manages input focus for the editor.
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);

          return GestureDetector(
            onTap: () {
              if (!focusNode.hasFocus) {
                focusNode.requestFocus();
              }
            },
            child: _ImageWrapper(
              child: _buildOverlay(
                  context,
                  Image(
                    image: controller.image,
                    fit: BoxFit.contain,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    Widget child,
  ) {
    final ctheme = BoustroComponentConfig.of(context);
    final scope = BoustroScope.of(context);
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<ImageEmbedController>('controller', controller));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
  }
}

/// Controller for [ImageEmbed].
class ImageEmbedController extends ValueNotifier<ImageProvider>
    implements ParagraphEmbedController {
  /// Create an image embed controller with an initial image provider.
  ImageEmbedController({required ImageProvider value}) : super(value);

  /// Get the image provider.
  ImageProvider get image => value;

  @override
  Widget createEditor(BuildContext context, FocusNode focusNode) {
    return ImageEmbedEditor(controller: this, focusNode: focusNode);
  }

  @override
  ParagraphEmbed? toEmbed() {
    return ImageEmbed(value);
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
extension ImageEmbedThemeSet on BoustroComponentConfigBuilder {
  /// Set the max height for an image embed.
  set imageMaxHeight(double? value) {
    this['imageMaxHeight'] = DoubleThemeProperty.maybe(value);
  }

  /// Set the color painted to the side of the image.
  set imageSideColor(Color? value) {
    this['imageSideColor'] = ColorThemeProperty.maybe(value);
  }

  /// Set the closure that's called when an image should be picked.
  set imagePickImage(PickImage? value) {
    this['imagePickImage'] = UnlerpableThemeProperty.maybe<PickImage>(value);
  }
}
