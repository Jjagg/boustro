import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'document_controller.dart';
import 'nested_list_controller.dart';
import 'theme.dart';

/// Builds a toolbar item into a widget.
typedef ToolbarItemBuilder = Widget Function(
  BuildContext context,
  DocumentController controller,
  ToolbarItem item,
);

/// Builds a widget given a [BuildContext] and a [DocumentController].
/// Used in [ToolbarItem.custom].
typedef CustomToolbarItemBuilder = Widget Function(
  BuildContext context,
  DocumentController controller,
);

/// Called when a toolbar item is pressed.
typedef ToolbarItemCallback = void Function(
  BuildContext context,
  DocumentController controller,
);

/// Item in a [Toolbar].
@immutable
class ToolbarItem extends StatelessWidget with NestedListItem<ToolbarItem> {
  const ToolbarItem._({
    this.title,
    this.tooltip,
    this.builder,
    List<ToolbarItem> items = const [],
    ToolbarItemCallback? onPressed,
  })  : _items = items,
        _onPressed = onPressed;

  /// Create a toolbar item that can use the document controller.
  // ignore: sort_unnamed_constructors_first
  const ToolbarItem({
    required Widget title,
    required ToolbarItemCallback? onPressed,
    ToolbarItemBuilder? builder,
    String? tooltip,
  }) : this._(
            title: title,
            builder: builder,
            onPressed: onPressed,
            tooltip: tooltip);

  /// Create a toolbar item that builds any widget.
  factory ToolbarItem.custom({required CustomToolbarItemBuilder builder}) {
    return ToolbarItem._(
        builder: (context, controller, _) => builder(context, controller));
  }

  /// Create a toolbar item that - when clicked - shows a submenu of other
  /// items.
  const ToolbarItem.sublist({
    required Widget title,
    required List<ToolbarItem> items,
    String? tooltip,
  }) : this._(title: title, items: items, tooltip: tooltip);

  /// Core display of the item. Commonly [Icon] or [Text].
  final Widget? title;

  /// Function that builds this item into a widget.
  final ToolbarItemBuilder? builder;
  final ToolbarItemCallback? _onPressed;
  final List<ToolbarItem> _items;

  /// Help text displayed in a tooltip and included in [Semantics] for
  /// accessibility.
  final String? tooltip;

  @override
  List<ToolbarItem> get items => _items;

  /// Executed when this item is pressed.
  ///
  /// If [ToolbarItem.sublist] is used, this will push the sublist
  /// to the stack of toolbar item lists and it will be shown on top of
  /// the toolbar this item is a part of.
  ToolbarItemCallback? get onPressed =>
      hasItems ? ((context, _) => super.sublistCallback(context)) : _onPressed;

  @override
  Widget build(BuildContext context) {
    final toolbarScope = _ToolbarScope.of(context);
    assert(() {
      if (toolbarScope == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('No Toolbar found.'),
          ErrorDescription('Toolbar items need to be inside a Toolbar.'),
          ErrorHint('Include a Toolbar widget '
              'above this one in the widget tree.'),
        ]);
      }

      return true;
    }(), 'unreachable');

    final controller = toolbarScope!.controller;
    final builder = this.builder ?? toolbarScope.defaultItemBuilder;

    return builder(context, controller, this);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Widget>('title', title))
      ..add(ObjectFlagProperty<ToolbarItemBuilder?>.has('builder', builder))
      ..add(StringProperty('tooltip', tooltip, defaultValue: null))
      ..add(IterableProperty<ToolbarItem>('items', items))
      ..add(
          ObjectFlagProperty<ToolbarItemCallback?>.has('onPressed', onPressed));
  }
}

class _ToolbarScope extends InheritedWidget {
  const _ToolbarScope({
    Key? key,
    required this.controller,
    required this.defaultItemBuilder,
    required Widget child,
  }) : super(key: key, child: child);

  // ignore: diagnostic_describe_all_properties
  final DocumentController controller;
  // ignore: diagnostic_describe_all_properties
  final ToolbarItemBuilder defaultItemBuilder;

  static _ToolbarScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ToolbarScope>();
  }

  @override
  bool updateShouldNotify(covariant _ToolbarScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// A horizontal bar that displays buttons to interact with a
/// [DocumentController].
class Toolbar extends StatelessWidget {
  /// Create a toolbar.
  const Toolbar({
    Key? key,
    required this.documentController,
    required this.defaultItemBuilder,
    required this.items,
  }) : super(key: key);

  /// The controller that the toolbar items will have access to to modify the
  /// document or display document state.
  final DocumentController documentController;

  /// Default builder for items that do not have [ToolbarItem.builder] set.
  final ToolbarItemBuilder defaultItemBuilder;

  /// The toolbar items that are displayed by this toolbar.
  final List<ToolbarItem> items;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    final padding = btheme.toolbarPadding ??
        BoustroThemeData.fallbackForContext(context).toolbarPadding!;
    return Container(
      height: btheme.toolbarHeight,
      decoration: btheme.toolbarDecoration,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: padding,
          child: _ToolbarItemsBuilder(
            documentController: documentController,
            defaultItemBuilder: defaultItemBuilder,
            items: items,
          ),
        ),
      ),
    );
  }

  /// Pop a nested menu of the stack.
  ///
  /// To build nested menus use [ToolbarItem.sublist].
  static void popMenu(BuildContext context) {
    DefaultNestedListController.of<ToolbarItem>(context)!.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DocumentController>(
        'documentController', documentController));
    properties.add(ObjectFlagProperty<ToolbarItemBuilder>.has(
        'defaultItemBuilder', defaultItemBuilder));
  }
}

class _ToolbarItemsBuilder extends StatelessWidget {
  const _ToolbarItemsBuilder({
    Key? key,
    required this.documentController,
    required this.defaultItemBuilder,
    required this.items,
  }) : super(key: key);

  // ignore: diagnostic_describe_all_properties
  final DocumentController documentController;
  // ignore: diagnostic_describe_all_properties
  final ToolbarItemBuilder defaultItemBuilder;
  final List<ToolbarItem> items;

  @override
  Widget build(BuildContext context) {
    return _ToolbarScope(
      controller: documentController,
      defaultItemBuilder: defaultItemBuilder,
      child: DefaultNestedListController<ToolbarItem>(
        rootItems: items,
        child: Builder(
          builder: (context) {
            final controller =
                DefaultNestedListController.of<ToolbarItem>(context)!;
            final theme = BoustroTheme.of(context);

            Widget list = ListView(
                key: Key(controller.depth.toString()),
                scrollDirection: Axis.horizontal,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemExtent: theme.toolbarItemExtent,
                children: controller.currentItems);

            if (controller.isNested) {
              list = Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: list),
                  ToolbarItem(
                    onPressed: (_, __) => controller.pop(),
                    tooltip: 'Close',
                    title: const Icon(Icons.close),
                  )
                ],
              );
            }

            return AnimatedSwitcher(
              duration: theme.toolbarFadeDuration ??
                  BoustroThemeData.fallbackForContext(context)
                      .toolbarFadeDuration!,
              child: list,
            );
          },
        ),
      ),
    );
  }
}
