import 'dart:async';
import 'dart:math' as math;

import 'package:boustro/src/widgets/text_watcher.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:boustro/boustro.dart';

import 'paragraphs/image_paragraph.dart';

// === ATTRIBUTES ===

class ToolbarButtonState with EquatableMixin {
  ToolbarButtonState({
    required this.enabled,
    required this.toggled,
  });

  final bool enabled;
  final bool toggled;

  @override
  List<Object?> get props => [enabled, toggled];
}

class ToolbarItemButton extends StatelessWidget {
  const ToolbarItemButton({
    Key? key,
    required this.controller,
    required this.item,
    this.toggledSelector,
    this.enabledSelector,
  }) : super(key: key);

  ToolbarItemButton.attribute({
    Key? key,
    required this.controller,
    required this.item,
    required TextAttribute attribute,
    this.enabledSelector,
  })  : toggledSelector =
            ((AttributedTextEditingController c) => c.isApplied(attribute)),
        super(key: key);

  final DocumentController controller;
  final ToolbarItem item;
  final bool Function(AttributedTextEditingController)? toggledSelector;
  final bool Function(AttributedTextEditingController)? enabledSelector;

  @override
  Widget build(BuildContext context) {
    return FocusedTextParagraphWatcher<ToolbarButtonState>(
      enabled: toggledSelector != null || enabledSelector != null,
      controller: controller,
      defaultValue: ToolbarButtonState(enabled: true, toggled: false),
      select: (textController) {
        final enabled = enabledSelector?.call(textController) ?? true;
        if (!enabled) {
          return ToolbarButtonState(enabled: enabled, toggled: false);
        }

        final toggled = toggledSelector?.call(textController) ?? false;
        return ToolbarButtonState(enabled: enabled, toggled: toggled);
      },
      builder: (context, state, _) {
        return ToggleableToolbarButtonWrapper(
          toggled: state.enabled && state.toggled,
          child: Center(
            child: ToolbarIconButton(
              controller: controller,
              item: item,
              enabled: state.enabled,
            ),
          ),
        );
      },
    );
  }
}

class ToggleableToolbarButtonWrapper extends StatelessWidget {
  const ToggleableToolbarButtonWrapper({
    Key? key,
    required this.toggled,
    required this.child,
  }) : super(key: key);

  final bool toggled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!toggled) {
      return child;
    }

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          color: decorationColor,
        ),
        child: child,
      ),
    );
  }
}

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    Key? key,
    required this.controller,
    required this.item,
    this.enabled = true,
  }) : super(key: key);

  final DocumentController controller;
  final ToolbarItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashColor: Colors.transparent,
      onPressed: !enabled || item.onPressed == null
          ? null
          : () => item.onPressed!(context, controller),
      icon: item.title!,
      tooltip: item.tooltip,
    );
  }
}

/// Helper function to easily create a toolbar item that toggles a specific
/// attribute.
ToolbarItem createToggleableToolbarItem(
  String tooltip,
  TextAttribute attribute,
  IconData icon,
) {
  return ToolbarItem(
    builder: (context, controller, item) => ToolbarItemButton.attribute(
      controller: controller,
      item: item,
      attribute: attribute,
    ),
    title: Icon(icon),
    onPressed: (_, controller) {
      final focusedLine = controller.getFocusedText();
      focusedLine?.textController.toggleAttribute(attribute);
    },
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
//ToolbarItem title = ToolbarItem(
//  builder: _createToggleableToolbarItemBuilder(
//      (controller) => controller.getModifierListener(heading1Modifier)),
//  title: const Icon(Icons.title),
//  onPressed: (_, controller) => controller.toggleLineModifier(heading1Modifier),
//);

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
    onPressed: (context, controller) => _applyLink(
      context: context,
      controller: controller,
      uriHintText: uriHintText,
      processInput: processInput,
      validator: validator,
    ),
    builder: (context, controller, item) {
      return ToolbarItemButton(
        controller: controller,
        item: item,
        enabledSelector: (c) =>
            c.selection.isValid &&
            (!c.selection.isCollapsed ||
                c.getAppliedSpansWithType<LinkAttribute>().isNotEmpty),
        toggledSelector: (c) =>
            c.getAppliedSpansWithType<LinkAttribute>().isNotEmpty,
      );
    },
  );
}

Future<void> _applyLink({
  required BuildContext context,
  required DocumentController controller,
  required String uriHintText,
  String Function(String)? processInput,
  FormFieldValidator<String>? validator,
}) async {
  final line = controller.getFocusedText();
  if (line != null) {
    final c = line.textController;
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
}

ToolbarItem? _buildImageButton({
  required IconData icon,
  required String tooltip,
  required Future<ImageProvider<Object>?> Function(BuildContext)? getImage,
}) {
  if (getImage == null) {
    return null;
  }

  return ToolbarItem(
    title: Icon(icon),
    tooltip: tooltip,
    onPressed: (context, controller) async {
      final img = await getImage(context);
      if (img != null) {
        final ParagraphController pc;
        // FIXME I've run into cases where the controller's scope node has
        // primary focus even though there's no focused paragraph.
        //if (controller.focusNode.hasFocus) {
        final index = controller.getFocusedParagraphIndex();
        if (index != null) {
          pc = controller.insert(
            index + 1,
            ImageParagraph(image: img),
          );
        } else {
          pc = controller.append(ImageParagraph(image: img));
        }
        pc.focusNode.requestFocus();
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
