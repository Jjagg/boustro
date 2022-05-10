import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/document_controller.dart';

/// Exposes a [DocumentController].
@immutable
class BoustroScope extends InheritedWidget {
  /// Create a scope for an editable document with a [DocumentController].
  const BoustroScope({
    Key? key,
    required DocumentController this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  /// Document controller of the editor.
  final DocumentController controller;

  /// Look for a boustro scope widget up the tree from [context].
  ///
  /// Returns null if there is no [BoustroScope] ancestor.
  static BoustroScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BoustroScope>();
  }

  /// Look for a boustro scope widget up the tree from [context].
  ///
  /// Throws if there is no [BoustroScope] ancestor.
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
    return controller != oldWidget.controller;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DocumentController?>('controller', controller,
          defaultValue: null));
  }
}
