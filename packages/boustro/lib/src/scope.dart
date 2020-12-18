import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'document.dart';
import 'widgets/document_controller.dart';
import 'widgets/editor.dart';

/// Inherited widget that carries information about a document.
@immutable
class BoustroScope extends InheritedWidget {
  /// Create a scope for an editable document with a [DocumentController].
  const BoustroScope.editable({
    Key? key,
    required DocumentController this.controller,
    required Widget child,
  })   : document = null,
        super(key: key, child: child);

  /// Create a scope for a read-only document with a [Document].
  const BoustroScope.readonly({
    Key? key,
    required Document this.document,
    required Widget child,
  })   : controller = null,
        super(key: key, child: child);

  /// Document controller of the editor. Null if [BoustroScope.readonly] was
  /// used.
  final DocumentController? controller;

  /// Document of the [DocumentView]. Null if [BoustroScope.readonly] was
  /// used.
  final Document? document;

  /// True if [BoustroScope.editable] was used, false if [BoustroScope.readonly]
  /// was used.
  bool get isEditable => controller != null;

  /// Call [editable] if [isEditable] is true or [readonly] if it is not.
  T match<T>({
    required T Function(DocumentController) editable,
    required T Function(Document) readonly,
  }) {
    return isEditable ? editable(controller!) : readonly(document!);
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
    return isEditable != oldWidget.isEditable;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isEditable', isEditable))
      ..add(DiagnosticsProperty<DocumentController?>('controller', controller,
          defaultValue: null))
      ..add(DiagnosticsProperty<Document?>('document', document,
          defaultValue: null));
  }
}
