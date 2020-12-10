// Adapted from
// https://github.com/jamesblasco/selection_controls_example/tree/09c5211589123353ff1945b78466e06e50ea19a5/lib/src/toolbar_context/controller.dart

import 'package:flutter/widgets.dart';

/// Base class for items managed by a [NestedListController].
mixin NestedListItem<T extends NestedListItem<T>> {
  /// Nested children of this item.
  List<T> get items;

  /// Returns true if [items] is not empty.
  bool get hasItems => items.isNotEmpty;

  /// Create a callback to push children to the nearest
  /// [DefaultNestedListController].
  ///
  /// Can be used as a callback for activation of menu items with nested items.
  @protected
  void sublistCallback(BuildContext context) {
    assert(() {
      if (context.widget is! DefaultNestedListController &&
          context.findAncestorWidgetOfExactType<
                  DefaultNestedListController<T>>() ==
              null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('No DefaultNestedListController<$T> found.'),
          ErrorDescription('Sublists use DefaultNestedListController to '
              'maintain their state. Therefore a DefaultNestedListController '
              '''with matching type '$T' must be in the tree above a '''
              'NestedListItem.'),
          ErrorHint('You can include a DefaultNestedListController<$T> widget '
              'above this one in the widget tree.'),
        ]);
      }

      return true;
    }(), 'unnreachable');

    DefaultNestedListController.of<T>(context)!.push(this as T);
  }
}

/// List of [NestedListItem] with their parent item.
class NestedItemList<T extends NestedListItem<T>> {
  const NestedItemList(this._items) : parent = null;
  NestedItemList.fromParent(T parent)
      : parent = parent,
        _items = parent.items;

  final T? parent;
  final List<T> _items;
  List<T> get items => parent?.items ?? _items;
}

/// Manages a stack of lists for nested menus.
class NestedListController<T extends NestedListItem<T>> extends ChangeNotifier {
  NestedListController({required List<T> rootItems})
      : _listStack = [NestedItemList(rootItems)];

  final List<NestedItemList<T>> _listStack;

  /// Number of menus deep we are nested.
  ///
  /// If there is only a root menu the depth is 0.
  int get depth => _listStack.length - 1;

  /// Push [parent]s children to the stack.
  void push(T parent) {
    assert(parent.hasItems, 'Only items with children can be nested');
    _listStack.add(NestedItemList.fromParent(parent));
    notifyListeners();
  }

  /// Pop the last list of items from the stack. Always leaves one list on the
  /// stack.
  ///
  /// Returns true if a list was actually popped, false if there was only one
  /// list on the stack and this call had no effect (i.e. [isNested] was false).
  bool pop() {
    if (_listStack.length > 1) {
      _listStack.removeLast();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// True if there is more than 1 list of items on the stack.
  bool get isNested => _listStack.length > 1;

  /// Parent of the last item list in the stack. Null if the last list
  /// is the root list.
  T? get currentParent => _listStack.last.parent;

  /// Items from the last [NestedItemList] on the stack.
  List<T> get currentItems => _listStack.last._items;
}

class DefaultNestedListController<T extends NestedListItem<T>>
    extends StatefulWidget {
  const DefaultNestedListController({
    Key? key,
    required this.rootItems,
    required this.child,
  }) : super(key: key);

  final List<T> rootItems;
  final Widget child;

  @override
  _DefaultNestedListControllerState<T> createState() =>
      _DefaultNestedListControllerState<T>();

  static NestedListController<T>? of<T extends NestedListItem<T>>(
      BuildContext context) {
    final defaultController = context
        .dependOnInheritedWidgetOfExactType<_NestedListControllerScope<T>>();
    return defaultController?.notifier;
  }
}

class _DefaultNestedListControllerState<T extends NestedListItem<T>>
    extends State<DefaultNestedListController<T>> {
  late final controller = NestedListController<T>(rootItems: widget.rootItems)
    ..addListener(update);

  @override
  Widget build(BuildContext context) {
    return _NestedListControllerScope<T>(
      controller: controller,
      child: widget.child,
    );
  }

  void update() {
    setState(() {});
  }

  @override
  void dispose() {
    controller
      ..removeListener(update)
      ..dispose();
    super.dispose();
  }
}

class _NestedListControllerScope<T extends NestedListItem<T>>
    extends InheritedNotifier<NestedListController<T>> {
  const _NestedListControllerScope({
    required NestedListController<T> controller,
    required Widget child,
  }) : super(child: child, notifier: controller);
}
