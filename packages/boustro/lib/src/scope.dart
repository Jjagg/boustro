import 'package:flutter/widgets.dart';

import 'widgets/document_controller.dart';

class BoustroScope extends InheritedWidget {
  BoustroScope.editable({
    required DocumentController controller,
    required Widget child,
  })   : controller = controller,
        super(child: child);

  BoustroScope.readonly({
    required Widget child,
  })   : controller = null,
        super(child: child);

  final DocumentController? controller;

  bool get editable => controller != null;

  static BoustroScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BoustroScope>();
    if (scope == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'BoustroScope.of() called with a context that does not contain a BoustroScope.'),
        ErrorDescription(
            '${context.widget.runtimeType} widgets require a BoustroScope widget ancestor.'),
        context.describeWidget(
            'The specific widget that could not find a BoustroScope was'),
        context.describeOwnershipChain(
            'The ownership chain for the affected widget is'),
        ErrorHint(
            'No BoustroScope ancestor could be found starting from the context that was passed '
            'to BoustroScope.of(). Make sure you have a BoustroEditor or BoustroView, or include '
            'a BoustroScope directly.'),
        ...context.describeMissingAncestor(expectedAncestorType: BoustroScope),
      ]);
    }
    return scope;
  }

  @override
  bool updateShouldNotify(covariant BoustroScope oldWidget) {
    return editable != oldWidget.editable;
  }
}
