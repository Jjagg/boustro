import 'package:flutter/widgets.dart';

import 'document.dart';
import 'scope.dart';
import 'widgets/editor.dart';

/// Determines how a [BoustroEditor] displays a
/// [BoustroDocument].
//@immutable
//class BoustroContext {
//  /// Create a boustro context.
//  BoustroContext({
//    List<LineParagraphModifier>? lineHandlers,
//    List<ParagraphEmbedBuilder>? embedHandlers,
//  }) : this._(
//          lineHandlers ?? const [],
//          {for (var h in embedHandlers ?? <ParagraphEmbedBuilder>[]) h.type: h},
//        );
//
//  BoustroContext._(
//    List<LineParagraphModifier> lineHandlers,
//    Map<String, ParagraphEmbedBuilder> paragraphEmbedBuilders,
//  )   : lineHandlers =
//            lineHandlers.sorted((l, r) => r.priority - l.priority).build(),
//        paragraphEmbedBuilders = paragraphEmbedBuilders.build();
//
//  /// Supported line modifiers for this context.
//  ///
//  /// These are always sorted by [LineParagraphModifier.priority].
//  final BuiltList<LineParagraphModifier> lineHandlers;
//
//  /// Maps supported embeds to their builders.
//  final BuiltMap<String, ParagraphEmbedBuilder> paragraphEmbedBuilders;
//}

/// Wraps a line to modify how it's displayed.
abstract class LineModifier {
  /// Constant base constructor for implementations.
  const LineModifier();

  /// Build a text paragraph with some modification.
  Widget modify(
    BuildContext context,
    Widget child,
  );
}
