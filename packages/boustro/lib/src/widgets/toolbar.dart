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

/// Called when a toolbar item is pressed.
typedef ToolbarItemCallback = void Function(
  BuildContext context,
  DocumentController controller,
);

/// Item in a [Toolbar].
@immutable
class ToolbarItem extends StatelessWidget with NestedListItem<ToolbarItem> {
  const ToolbarItem._({
    required this.title,
    required this.tooltip,
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

  /// Create a toolbar item with a widget that does not depend
  /// on the document controller (apart from the [onPressed] callback).
  const ToolbarItem.simple({
    required Widget child,
    required ToolbarItemCallback? onPressed,
    String? tooltip,
  }) : this._(title: child, onPressed: onPressed, tooltip: tooltip);

  /// Create a toolbar item that - when clicked - shows a submenu of other
  /// items.
  const ToolbarItem.sublist({
    required Widget title,
    required List<ToolbarItem> items,
    String? tooltip,
  }) : this._(title: title, items: items, tooltip: tooltip);

  /// Core display of the item. Commonly [Icon] or [Text].
  final Widget title;

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
  ToolbarItemCallback? get onPressed => this.hasItems
      ? ((context, _) => super.sublistCallback(context))
      : _onPressed;

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
    }(), 'unnreachable');

    toolbarScope!;

    final controller = toolbarScope.controller;
    final builder = this.builder ?? toolbarScope.defaultItemBuilder;

    return builder(context, controller, this);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Widget>('title', title))
      ..add(ObjectFlagProperty<ToolbarItemBuilder?>.has('builder', builder))
      ..add(StringProperty('tooltip', tooltip))
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

  final DocumentController controller;
  final ToolbarItemBuilder defaultItemBuilder;

  static _ToolbarScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ToolbarScope>();
  }

  @override
  bool updateShouldNotify(covariant _ToolbarScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    Key? key,
    required this.documentController,
    required this.defaultItemBuilder,
    required this.items,
  }) : super(key: key);

  final DocumentController documentController;
  final ToolbarItemBuilder defaultItemBuilder;
  final List<ToolbarItem> items;

  @override
  Widget build(BuildContext context) {
    final btheme = BoustroTheme.of(context);
    return Container(
      height: btheme.toolbarHeight,
      decoration: btheme.toolbarDecoration,
      child: Padding(
        padding: btheme.toolbarPadding,
        child: _ToolbarItemsBuilder(
          documentController: documentController,
          defaultItemBuilder: defaultItemBuilder,
          items: items,
        ),
      ),
    );
  }
}

class _ToolbarItemsBuilder extends StatelessWidget {
  const _ToolbarItemsBuilder({
    Key? key,
    required this.documentController,
    required this.defaultItemBuilder,
    required this.items,
  }) : super(key: key);

  final DocumentController documentController;
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
                  ToolbarItem.simple(
                    onPressed: (_, __) => controller.pop(),
                    tooltip: 'Close',
                    child: const Icon(Icons.close),
                  )
                ],
              );
            }

            return AnimatedSwitcher(
              duration: theme.toolbarFadeDuration,
              child: list,
            );
          },
        ),
      ),
    );
  }
}
