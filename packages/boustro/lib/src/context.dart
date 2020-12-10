import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'document.dart';
import 'scope.dart';
import 'widgets/document_controller.dart';
import 'widgets/editor.dart';

/// Determines how a [BoustroEditor] displays a
/// [BoustroDocument].
@immutable
class BoustroContext {
  /// Create a boustro context.
  BoustroContext({
    List<LineParagraphModifier>? lineHandlers,
    List<ParagraphEmbedBuilder>? embedHandlers,
  }) : this._(
          lineHandlers ?? const [],
          {
            for (var h in embedHandlers ?? <ParagraphEmbedBuilder>[])
              h.key: h
          },
        );

  BoustroContext._(
    List<LineParagraphModifier> lineHandlers,
    Map<String, ParagraphEmbedBuilder> paragraphEmbedBuilders,
  )   : lineHandlers =
            lineHandlers.sorted((l, r) => r.priority - l.priority).build(),
        paragraphEmbedBuilders = paragraphEmbedBuilders.build();

  /// Supported line modifiers for this context.
  ///
  /// These are always sorted by [LineParagraphModifier.priority].
  final BuiltList<LineParagraphModifier> lineHandlers;

  /// Maps supported embeds to their builders.
  final BuiltMap<String, ParagraphEmbedBuilder> paragraphEmbedBuilders;
}

/// Handler for building paragraph embeds.
///
/// Each key should map to one handler.
abstract class ParagraphEmbedBuilder {
  const ParagraphEmbedBuilder();

  /// Identifier for this embed.
  String get key;

  /// Function that builds the embed widget.
  Widget buildEmbed(
    BoustroScope scope,
    BoustroParagraphEmbed embed, [
    FocusNode? focusNode,
  ]);
}

abstract class LineParagraphModifier {
  const LineParagraphModifier();

  /// Determines the order in which line handlers are applied.
  ///
  /// Higher priority handlers are executed first and their result will
  /// be passed on to other handlers. So the result of the highest
  /// priority handler will be the deepest in the hierarchy and the closest
  /// to the actual text.
  int get priority;

  /// True if this line handler should be applied to
  /// a line with [properties].
  bool shouldBeApplied(Map<String, Object> properties);

  /// Build a text paragraph with some modification.
  Widget modify(
    BuildContext context,
    Map<String, Object> properties,
    Widget child,
  );
}
