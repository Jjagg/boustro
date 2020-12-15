import 'dart:math' as math;
import 'package:boustro/boustro.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'attributes.dart';

Widget Function(
  BuildContext context,
  DocumentController controller,
  ToolbarItem item,
) _createToggleableToolbarItemBuilder(TextAttribute attribute) {
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
      valueListenable: controller.listen(attribute),
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
  IconData icon, {
  InsertBehavior startBehavior = InsertBehavior.exclusive,
  InsertBehavior endBehavior = InsertBehavior.inclusive,
}) {
  return ToolbarItem(
    builder: _createToggleableToolbarItemBuilder(attribute),
    title: Icon(icon),
    onPressed: (_, controller) =>
        controller.focusedLine?.controller.toggleAttribute(
      attribute,
      InsertBehavior.exclusive,
      InsertBehavior.inclusive,
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
