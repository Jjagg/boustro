import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/document.dart';

/// A readonly view of a [Document].
class DocumentView extends StatelessWidget {
  /// Create a document view.
  ///
  /// [document] is the content that will be displayed.
  const DocumentView({
    Key? key,
    required this.document,
    this.physics,
    this.primaryScroll,
    this.scrollController,
  }) : super(key: key);

  /// The contents this view will display.
  final Document document;

  /// ScrollPhysics to pass to the [ListView] that holds the paragraphs.
  /// See [ScrollView.physics].
  final ScrollPhysics? physics;

  /// Whether the document view is the primary scroll view.
  /// See [ScrollView.primary].
  final bool? primaryScroll;

  /// The scroll controller for the [ScrollView] containing the paragraphs.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      addAutomaticKeepAlives: false,
      controller: scrollController,
      physics: physics,
      primary: primaryScroll,
      shrinkWrap: true,
      itemCount: document.paragraphs.length,
      itemBuilder: (context, index) {
        final paragraph = document.paragraphs[index];
        return paragraph.buildView(context);
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Document>('document', document));
    properties.add(DiagnosticsProperty<ScrollPhysics?>('physics', physics,
        defaultValue: null));
    properties.add(FlagProperty('primaryScroll',
        value: primaryScroll, ifTrue: 'primaryScroll'));
    properties.add(DiagnosticsProperty<ScrollController?>(
        'scrollController', scrollController,
        defaultValue: null));
  }
}
