import 'dart:math' as math;

import 'package:boustro/boustro.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'attributes.dart';
import 'embeds/image_embed.dart';
import 'line_modifiers.dart';

// === ATTRIBUTES ===

Widget Function(
  BuildContext context,
  DocumentController controller,
  ToolbarItem item,
) _createToggleableToolbarItemBuilder(
  ValueListenable<bool> Function(DocumentController) getListener,
) {
  return (context, controller, item) {
    final btheme = BoustroTheme.of(context);

    final toolbarColor = btheme.toolbarDecoration?.color ??
        btheme.toolbarDecoration?.gradient?.colors.firstOrNull ??
        BoustroThemeData.fallbackForContext(context).toolbarDecoration!.color ??
        BoustroThemeData.fallbackForContext(context)
            .toolbarDecoration!
            .gradient
            ?.colors
            .firstOrNull;

    final Color? decorationColor;

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

    return ValueListenableBuilder<bool>(
      valueListenable: getListener(controller),
      builder: (context, toggled, button) {
        if (!toggled) {
          return button!;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Container(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              color: decorationColor,
            ),
            child: button,
          ),
        );
      },
      child: Center(
        child: IconButton(
          splashColor: Colors.transparent,
          onPressed: item.onPressed == null
              ? null
              : () => item.onPressed!(context, controller),
          icon: item.title,
          tooltip: item.tooltip,
        ),
      ),
    );
  };
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
              if (controller.focusNode.hasFocus) {
                embed = controller.insertEmbedAtCurrent(ImageEmbed(img))!;
              } else {
                embed = controller.appendEmbed(ImageEmbed(img));
              }
              embed.focusNode.requestFocus();
              Toolbar.popMenu(context);
            }
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
