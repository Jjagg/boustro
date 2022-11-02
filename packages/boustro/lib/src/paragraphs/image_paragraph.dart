import 'dart:io';

import 'package:boustro/boustro.dart';
import 'package:boustro/convert_json.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paragraph that displays an image.
@immutable
class ImageParagraph extends Paragraph with EquatableMixin {
  /// Create an image paragraph.
  const ImageParagraph({required this.image, this.alt});

  /// Provider for the image.
  final ImageProvider image;

  /// Alt text for the image.
  final String? alt;

  @override
  Widget buildView(BuildContext context) {
    return ImageParagraphView(image: image, alt: alt);
  }

  @override
  ParagraphController createController() {
    return ImageEmbedController(ImageData(image: image, alt: alt));
  }

  @override
  List<Object?> get props => [image];
}

/// The widget that [ImageParagraph] uses to wrap its [Image] by default.
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

    return ColoredBox(
      color: sideColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}

/// Widget for [ImageParagraph].
class ImageParagraphView extends StatelessWidget {
  /// Create an [ImageParagraphView].
  const ImageParagraphView({
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
    final maxHeight = config.imageMaxHeight ?? 1000;

    return Padding(
      padding: padding.resolve(Directionality.of(context)),
      child: ImageWrapper(
        child: Center(
          heightFactor: 1,
          child: Image(
            fit: BoxFit.contain,
            semanticLabel: alt,
            image: image,
            frameBuilder: (context, child, frame, _) {
              if (frame == null) return SizedBox(height: maxHeight);
              return child;
            },
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

/// Editor for [ImageParagraph].
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
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
          },
          child: ImageWrapper(
            child: ImageEditorOverlay(
              controller: controller,
              enableImageEdit: enableImageEdit,
              enableAltTextEdit: enableAltTextEdit,
              child: _ChangeNotifierBuilder(
                notifier: controller,
                builder: (context) {
                  return Image(
                    fit: BoxFit.contain,
                    semanticLabel: controller.alt,
                    image: controller.image,
                  );
                },
              ),
            ),
          ),
        ),
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

class ImageEditorOverlay extends StatelessWidget {
  const ImageEditorOverlay({
    Key? key,
    required this.controller,
    required this.enableImageEdit,
    required this.enableAltTextEdit,
    required this.child,
  }) : super(key: key);

  /// Controller that manages the current image provider.
  final ImageEmbedController controller;

  final bool enableImageEdit;
  final bool enableAltTextEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            child: Visibility(
              visible: hasFocus,
              child: Stack(
                children: [
                  if (enableImageEdit && pickImg != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ImageEditorButton(
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
                      child: ImageEditorButton(
                        icon: Icons.close,
                        onPressed: () {
                          final documentController = scope.controller;
                          final index =
                              documentController.paragraphs.indexOf(controller);
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
                        child: ImageEditorButton(
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
}

class ImageEditorButton extends StatelessWidget {
  const ImageEditorButton({
    Key? key,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
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

/// Controller for [ImageParagraph].
class ImageEmbedController extends ParagraphController with ChangeNotifier {
  /// Create an image embed controller with initial image data.
  ImageEmbedController(this._data);

  ImageData _data;

  /// Get the image data.
  ImageData get data => _data;

  /// Set the image data.
  set data(ImageData value) {
    if (_data != data) {
      this._data = value;
      notifyListeners();
    }
  }

  /// Get the image provider.
  ImageProvider get image => data.image;

  /// Set the image provider.
  set image(ImageProvider image) => data = data.copyWith(image: image);

  /// Get the alt text.
  String? get alt => data.alt;

  /// Set the alt text.
  set alt(String? alt) => data = data.copyWith(alt: alt ?? '');

  @override
  Widget buildEditor(BuildContext context) {
    return ImageEmbedEditor(controller: this, focusNode: focusNode);
  }

  @override
  Paragraph? toParagraph() {
    return ImageParagraph(image: image, alt: alt);
  }
}

/// Signature for function used to pick an image.
typedef PickImage = Future<ImageProvider>? Function(BuildContext context);

/// Themeable property getter extensions for [ImageParagraph].
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

/// Themeable property setter extensions for [ImageParagraph].
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

/// Codec to convert [ImageParagraph] to/from JSON (see [DocumentJsonCodec]).
final image = ParagraphCodec<ImageParagraph>.stateful(
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
    if (imageStr.startsWith('file://') && !kIsWeb) {
      image = FileImage(File(imageStr.substring('file://'.length)));
    } else {
      image = NetworkImage(imageStr);
    }

    final alt = e['alt'] as String?;

    return ImageParagraph(image: image, alt: alt);
  },
);

class _ChangeNotifierBuilder extends StatefulWidget {
  const _ChangeNotifierBuilder({
    Key? key,
    required this.notifier,
    required this.builder,
  }) : super(key: key);

  final ChangeNotifier notifier;
  final WidgetBuilder builder;

  @override
  State<_ChangeNotifierBuilder> createState() => _ChangeNotifierBuilderState();
}

class _ChangeNotifierBuilderState extends State<_ChangeNotifierBuilder> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () => setState(() {});
    widget.notifier.addListener(_listener);
  }

  @override
  void didUpdateWidget(_ChangeNotifierBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifier != oldWidget.notifier) {
      oldWidget.notifier.removeListener(_listener);
      widget.notifier.addListener(_listener);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
