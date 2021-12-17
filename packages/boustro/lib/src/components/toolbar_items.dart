import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:boustro/boustro.dart';

// === ATTRIBUTES ===

ToolbarItemBuilder _createToggleableToolbarItemBuilder(
  ValueListenable<bool> Function(DocumentController) getToggledListener, {
  ValueListenable<bool> Function(DocumentController)? getEnabledListener,
}) {
  return (context, controller, item) {
    if (getEnabledListener != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: getEnabledListener(controller),
        builder: (context, enabled, child) => ValueListenableBuilder<bool>(
          valueListenable: getToggledListener(controller),
          builder: _buildToggleableButton,
          child: Center(
            child: _buildIconButton(context, item, controller, enabled),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: getToggledListener(controller),
      builder: _buildToggleableButton,
      child: Center(
        child: _buildIconButton(context, item, controller, true),
      ),
    );
  };
}

Widget _buildIconButton(BuildContext context, ToolbarItem item,
    DocumentController controller, bool enableTap) {
  return IconButton(
    splashColor: Colors.transparent,
    onPressed: !enableTap || item.onPressed == null
        ? null
        : () => item.onPressed!(context, controller),
    icon: item.title!,
    tooltip: item.tooltip,
  );
}

Widget _buildToggleableButton(
  BuildContext context,
  bool toggled,
  Widget? button,
) {
  final Color? decorationColor;
  final btheme = BoustroTheme.of(context);

  final toolbarColor = btheme.toolbarDecoration?.color ??
      btheme.toolbarDecoration?.gradient?.colors.firstOrNull ??
      BoustroThemeData.fallbackForContext(context).toolbarDecoration!.color ??
      BoustroThemeData.fallbackForContext(context)
          .toolbarDecoration!
          .gradient
          ?.colors
          .firstOrNull;

  if (toolbarColor != null) {
    final hslToolbarColor = HSLColor.fromColor(toolbarColor);
    decorationColor = hslToolbarColor
        .withLightness(math.max(0, hslToolbarColor.lightness - 0.1))
        .toColor();
  } else {
    final iconTheme = IconTheme.of(context);
    if (iconTheme.color != null && iconTheme.opacity != null) {
      decorationColor =
          iconTheme.color!.withOpacity(math.max(0, iconTheme.opacity! - 0.5));
    } else {
      decorationColor = null;
    }
  }
  if (!toggled) {
    return button!;
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    child: Container(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        color: decorationColor,
      ),
      child: button,
    ),
  );
}

/// Helper function to easily create a toolbar item that toggles a specific
/// attribute.
ToolbarItem createToggleableToolbarItem(
  String tooltip,
  TextAttribute attribute,
  IconData icon,
) {
  return ToolbarItem(
    builder: _createToggleableToolbarItemBuilder(
        (controller) => controller.getAttributeListener(attribute)),
    title: Icon(icon),
    onPressed: (_, controller) =>
        controller.focusedLine?.controller.toggleAttribute(
      attribute,
    ),
    tooltip: tooltip,
  );
}

/// Toolbar item that toggles the [boldAttribute] on the selected text.
final bold = createToggleableToolbarItem(
  'Bold',
  boldAttribute,
  Icons.format_bold_rounded,
);

/// Toolbar item that toggles the [italicAttribute] on the selected text.
final italic = createToggleableToolbarItem(
  'Italic',
  italicAttribute,
  Icons.format_italic_rounded,
);

/// Toolbar item that toggles the [underlineAttribute] on the selected text.
final underline = createToggleableToolbarItem(
  'Underline',
  underlineAttribute,
  Icons.format_underline_rounded,
);

/// Toolbar item that toggles the [HeadingModifier] with level 1 for the
/// focused line.
ToolbarItem title = ToolbarItem(
  builder: _createToggleableToolbarItemBuilder(
      (controller) => controller.getModifierListener(heading1Modifier)),
  title: const Icon(Icons.title),
  onPressed: (_, controller) => controller.toggleLineModifier(heading1Modifier),
);

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({
    this.text = '',
    this.hintText = '',
    this.validator,
  });

  /// Initial text for the link text field.
  final String text;

  /// Hint text for the link text field when [text] is empty.
  final String hintText;

  final FormFieldValidator<String>? validator;

  @override
  _LinkDialogState createState() => _LinkDialogState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
    properties.add(StringProperty('hintText', hintText));
  }
}

class _LinkDialogState extends State<_LinkDialog> {
  // ignore: diagnostic_describe_all_properties
  late final TextEditingController controller =
      TextEditingController(text: widget.text);
  final _formKey = GlobalKey<FormState>();
  bool triedApply = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          autofocus: true,
          autovalidateMode: triedApply ? AutovalidateMode.always : null,
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: widget.hintText,
          ),
          validator: (text) {
            if (text == null || text.isEmpty) {
              return null;
            }

            final isValid = Uri.tryParse(text) != null;
            return isValid ? null : 'Please enter a valid URI.';
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
        if (widget.text.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context, '');
            },
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, controller.text);
            } else {
              setState(() {
                triedApply = true;
              });
            }
          },
          child: const Text('Apply'),
        )
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('triedApply', value: triedApply, showName: true));
  }
}

/// Toolbar item that applies a [LinkAttribute]. Shows a dialog with a text
/// field for the url.
///
/// You can provide a custom processor to fix user input and a custom validator
/// to control accepted (processed) user input.
///
/// The default processInput prepends http:// to the input if a protocol is
/// missing. The default validator validates that the input is a valid URI.
ToolbarItem link({
  String uriHintText = 'google.com',
  String Function(String)? processInput,
  FormFieldValidator<String>? validator,
}) {
  return ToolbarItem(
    title: const Icon(Icons.link),
    tooltip: 'Link',
    onPressed: (context, controller) async {
      final line = controller.focusedLine;
      if (line != null) {
        final c = line.controller;
        if (c.selection.isValid) {
          final canApply = !c.selection.isCollapsed ||
              c.getAppliedSpansWithType<LinkAttribute>().isNotEmpty;

          if (canApply) {
            final attrs = c.getAppliedSpansWithType<LinkAttribute>();
            final initialSpan = attrs.firstOrNull;
            final initialUri =
                (initialSpan?.attribute as LinkAttribute?)?.uri ?? '';
            final range = initialSpan?.range ?? c.selectionRange;
            // Show the dialog. Null means do nothing, empty string means remove.
            var link = await showDialog<String>(
              context: context,
              builder: (context) {
                return _LinkDialog(
                  text: initialUri,
                  hintText: uriHintText,
                  validator: validator,
                );
              },
            );

            if (link != null) {
              if (processInput != null) {
                link = processInput(link);
              } else if (!link.contains('://')) {
                link = 'http://$link';
              }

              var spans = c.spans;

              spans = spans.removeTypeFrom<LinkAttribute>(range);
              if (link.isNotEmpty) {
                final uri = Uri.parse(link);
                final attr = LinkAttribute(uri.toString());
                final span = AttributeSpan(attr, range.start, range.end);
                spans = spans.merge(span);
              }

              c.spans = spans;
            }
          }
        }
      }
    },
    builder: (context, controller, item) =>
        _LinkToolbarItem(controller: controller, toolbarItem: item),
  );
}

class _LinkToolbarItem extends StatefulWidget {
  const _LinkToolbarItem({
    Key? key,
    required this.controller,
    required this.toolbarItem,
  }) : super(key: key);

  final DocumentController controller;
  final ToolbarItem toolbarItem;

  @override
  _LinkToolbarItemState createState() => _LinkToolbarItemState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DocumentController>('controller', controller));
  }
}

class _LinkToolbarItemState extends State<_LinkToolbarItem> {
  late final ValueNotifier<bool> enabledListener = ValueNotifier(false);
  late final StreamSubscription<LineValueChangedEvent> _lineChangedSubscription;

  @override
  void initState() {
    super.initState();
    _lineChangedSubscription =
        widget.controller.onLineValueChanged.listen(_handleLineValueChanged);
  }

  @override
  void dispose() {
    enabledListener.dispose();
    _lineChangedSubscription.cancel();
    super.dispose();
  }

  void _handleLineValueChanged(LineValueChangedEvent event) {
    final state = event.state;
    if (state.focusNode.hasPrimaryFocus) {
      enabledListener.value = state.controller.selection.isValid &&
          !state.controller.selection.isCollapsed;
    }
    //print(
    //    'Enabled ${state.controller.selection.isValid && !state.controller.selection.isCollapsed}');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: enabledListener,
      builder: (context, enabled, child) => ValueListenableBuilder<bool>(
        valueListenable:
            widget.controller.getAttributeTypeListener<LinkAttribute>(),
        builder: (context, toggled, child) => _buildToggleableButton(
          context,
          toggled,
          Center(
            child: _buildIconButton(
              context,
              widget.toolbarItem,
              widget.controller,
              enabled || toggled,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ValueNotifier<bool>>(
        'enabledListener', enabledListener));
  }
}

// === LINE MODIFIERS ===

/// Toolbar item that toggles the [bulletListModifier] for the focused line.
final bulletList = ToolbarItem(
  builder: _createToggleableToolbarItemBuilder(
      (controller) => controller.getModifierListener(bulletListModifier)),
  title: const Icon(Icons.list),
  onPressed: (_, controller) =>
      controller.toggleLineModifier(bulletListModifier),
);

// === EMBEDS ===

ToolbarItem? _buildImageButton({
  required IconData icon,
  required String tooltip,
  required Future<ImageProvider<Object>?> Function(BuildContext)? getImage,
}) {
  return getImage == null
      ? null
      : ToolbarItem(
          title: Icon(icon),
          tooltip: tooltip,
          onPressed: (context, controller) async {
            final img = await getImage(context);
            if (img != null) {
              final EmbedState embed;
              // FIXME I've run into cases where the controller's scope node has
              // primary focus even though there's no focused paragraph.
              //if (controller.focusNode.hasFocus) {
              final index = controller.focusedParagraphIndex;
              if (index != null) {
                embed = controller.insertEmbed(
                  index + 1,
                  ImageEmbed(image: img),
                );
              } else {
                embed = controller.appendEmbed(ImageEmbed(image: img));
              }
              embed.focusNode.requestFocus();
            }

            Toolbar.popMenu(context);
          },
        );
}

/// Create a toolbar item for inserting [ImageEmbed].
///
/// At least one of [pickImage] and [snapImage] must not be null.
///
/// Use [pickImage] for the action that picks an image from the device gallery.
/// Use [snapImage] to take a new photo using the device camera.
///
/// If both are specified a submenu will be added to select whether the camera
/// or the gallery should be opened.
ToolbarItem image({
  Future<ImageProvider<Object>?> Function(BuildContext)? pickImage,
  Future<ImageProvider<Object>?> Function(BuildContext)? snapImage,
}) {
  assert(pickImage != null || snapImage != null,
      'At least one of the callbacks should not be null.');
  final snapImageItem = _buildImageButton(
    icon: Icons.photo_camera,
    tooltip: 'Camera',
    getImage: snapImage,
  );
  final pickImageItem = _buildImageButton(
    icon: Icons.photo_library,
    tooltip: 'Gallery',
    getImage: pickImage,
  );

  if (snapImageItem == null) {
    return pickImageItem!;
  }

  if (pickImageItem == null) {
    return snapImageItem;
  }

  return ToolbarItem.sublist(
    title: const Icon(Icons.photo),
    items: [
      snapImageItem,
      pickImageItem,
    ],
    tooltip: 'Image',
  );
}
