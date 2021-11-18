import 'package:boustro/boustro.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embed that displays an image.
@immutable
class ImageEmbed extends ParagraphEmbed with EquatableMixin {
  /// Create an image embed.
  const ImageEmbed({required this.image, this.alt});

  /// Provider for the image.
  final ImageProvider image;

  /// Alt text for the image.
  final String? alt;

  @override
  Widget createView(BuildContext context) {
    return ImageEmbedView(image: image, alt: alt);
  }

  @override
  ParagraphEmbedController createController() {
    return ImageEmbedController(ImageData(image: image, alt: alt));
  }

  @override
  List<Object?> get props => [image];
}

/// The widget that [ImageEmbed] uses to wrap its [Image] by default.
class ImageWrapper extends StatelessWidget {
  /// Create an image wrapper with a child.
  const ImageWrapper({Key? key, required this.child}) : super(key: key);

  /// The child this widget wraps.
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
  const ImageEmbedView({
    Key? key,
    required this.image,
    this.alt,
  }) : super(key: key);

  /// Provider for the image.
  final ImageProvider image;

  /// Alt text, passed to [Image.semanticLabel].
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final config = BoustroComponentConfig.of(context);
    final padding =
        config.imagePadding ?? const EdgeInsets.symmetric(vertical: 10);
    return Padding(
      padding: padding.resolve(Directionality.of(context)),
      child: ImageWrapper(
        child: Center(
          heightFactor: 1,
          child: Image(
            fit: BoxFit.contain,
            semanticLabel: alt,
            image: image,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider<Object>>('image', image));
    properties.add(StringProperty('alt', alt));
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
    this.enableImageEdit = true,
    this.enableAltTextEdit = true,
  }) : super(key: key);

  /// Controller that manages the current image provider.
  final ImageEmbedController controller;

  /// Focus node that manages input focus for the editor.
  final FocusNode focusNode;

  /// If enabled there will be a button on top of the image to pick another
  /// image. True by default.
  final bool enableImageEdit;

  /// If enabled there will be a button on top of the image to change the alt
  /// text. True by default.
  final bool enableAltTextEdit;

  @override
  Widget build(BuildContext context) {
    final config = BoustroComponentConfig.of(context);
    final padding =
        config.imagePadding ?? const EdgeInsets.symmetric(vertical: 10);
    return Padding(
      padding: padding.resolve(Directionality.of(context)),
      child: Focus(
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
              child: ImageWrapper(
                child: _buildOverlay(
                  context,
                  ValueListenableBuilder<ImageData>(
                    valueListenable: controller,
                    builder: (context, imageData, _) => Image(
                      fit: BoxFit.contain,
                      semanticLabel: imageData.alt,
                      image: imageData.image,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
                  if (enableImageEdit && pickImg != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildButton(
                          context: context,
                          icon: Icons.edit,
                          onPressed: () async {
                            final image = await pickImg(context);
                            if (image != null) {
                              controller.data = ImageData(image: image);
                            }
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
                          final documentController = scope.controller!;
                          final index =
                              documentController.paragraphs.indexWhere(
                            (p) => p.match(
                                line: (_) => false,
                                embed: (e) => e.controller == controller),
                          );
                          documentController.removeParagraphAt(index);
                        },
                      ),
                    ),
                  ),
                  if (enableAltTextEdit)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildButton(
                          context: context,
                          icon: Icons.accessibility_new,
                          onPressed: () async {
                            // edit alt text
                            final alt = await showDialog<String?>(
                              context: context,
                              builder: (context) =>
                                  _AltTextDialog(text: controller.alt),
                            );
                            if (alt != null) {
                              controller.alt = alt;
                            }
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
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
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
    properties.add(FlagProperty('enableImageEdit',
        value: enableImageEdit, ifTrue: 'editable', ifFalse: 'not editable'));
    properties.add(FlagProperty('enableAltTextEdit',
        value: enableAltTextEdit,
        ifTrue: 'alt text editable',
        ifFalse: 'alt text not editable'));
  }
}

class _AltTextDialog extends StatefulWidget {
  const _AltTextDialog({Key? key, String? text})
      : _text = text,
        super(key: key);

  final String? _text;

  @override
  _AltTextDialogState createState() => _AltTextDialogState();
}

class _AltTextDialogState extends State<_AltTextDialog> {
  late final TextEditingController _altTextController =
      TextEditingController(text: widget._text);

  @override
  void dispose() {
    _altTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              _altTextController.text,
            );
          },
          child: const Text('Ok'),
        )
      ],
      title: const Text('Set alt text'),
      content: TextField(
        maxLines: null,
        controller: _altTextController,
        decoration: const InputDecoration(hintText: 'alt text'),
        maxLength: 1000,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
      ),
    );
  }
}

/// Data used to render an image.
@immutable
class ImageData {
  /// Create an image data object.
  const ImageData({required this.image, String? alt})
      : alt = alt == '' ? null : alt;

  /// Provider of the image.
  final ImageProvider image;

  /// Alt text for the image for accessibility.
  final String? alt;

  /// Create a copy of this object with the given fields overriden.
  ///
  /// To unset alt, pass the empty string.
  ImageData copyWith({ImageProvider? image, String? alt}) {
    return ImageData(
      image: image ?? this.image,
      alt: alt ?? this.alt,
    );
  }
}

/// Controller for [ImageEmbed].
class ImageEmbedController extends ValueNotifier<ImageData>
    implements ParagraphEmbedController {
  /// Create an image embed controller with initial image data.
  ImageEmbedController(ImageData value) : super(value);

  /// Get the image data.
  ImageData get data => value;

  /// Set the image data.
  set data(ImageData value) => this.value = value;

  /// Get the image provider.
  ImageProvider get image => value.image;

  /// Set the image provider.
  set image(ImageProvider image) => value = value.copyWith(image: image);

  /// Get the alt text.
  String? get alt => value.alt;

  /// Set the alt text.
  set alt(String? alt) => value = value.copyWith(alt: alt ?? '');

  @override
  Widget createEditor(BuildContext context, FocusNode focusNode) {
    return ImageEmbedEditor(controller: this, focusNode: focusNode);
  }

  @override
  ParagraphEmbed? toEmbed() {
    return ImageEmbed(image: image, alt: alt);
  }
}

/// Signature for function used to pick an image.
typedef PickImage = Future<ImageProvider>? Function(BuildContext context);

/// Themeable property getter extensions for [ImageEmbed].
extension ImageEmbedTheme on BoustroComponentConfigData {
  /// The maximum height of an image in logical pixels.
  ///
  /// Higher images will be resized, keeping their aspect ratio.
  /// The color in [imageSideColor] will be painted to the sides of the image.
  double? get imageMaxHeight => get<double>('imageMaxHeight');

  /// Get the padding around the image embed.
  EdgeInsets? get imagePadding => get<EdgeInsets>('imagePadding');

  /// Get the closure that's called when an image should be picked.
  PickImage? get imagePickImage => get<PickImage>('imagePickImage');

  /// Color painted to the side of the image if it does not cover the full
  /// width available to it.
  Color? get imageSideColor => get<Color>('imageSideColor');
}

/// Themeable property setter extensions for [ImageEmbed].
///
/// See the getters in [ImageEmbedTheme] for more information on the properties.
extension ImageEmbedThemeSet on BoustroComponentConfigBuilder {
  /// Set the maximum height for an image embed.
  set imageMaxHeight(double? value) {
    this['imageMaxHeight'] = DoubleThemeProperty.maybe(value);
  }

  /// Set the padding around the image embed.
  set imagePadding(EdgeInsets? value) {
    this['imagePadding'] = EdgeInsetsThemeProperty.maybe(value);
  }

  /// Set the closure that's called when an image should be picked.
  set imagePickImage(PickImage? value) {
    this['imagePickImage'] = UnlerpableThemeProperty.maybe<PickImage>(value);
  }

  /// Set the color painted to the side of the image.
  set imageSideColor(Color? value) {
    this['imageSideColor'] = ColorThemeProperty.maybe(value);
  }
}
