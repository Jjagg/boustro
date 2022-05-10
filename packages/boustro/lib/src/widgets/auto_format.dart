import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/document.dart';
import '../spans/attribute_span.dart';
import '../spans/attributed_text.dart';
import '../spans/attributed_text_editing_controller.dart';
import '../core/document_controller.dart';
import 'text_watcher.dart';

/// Attribute used by [AutoFormatter].
///
/// This attribute wraps another attribute and [resolve] will delegate to the
/// wrapped attribute.
///
/// This attribute is used by [AutoFormatter] so it can distinguish
/// automatically applied attributes from manually applied attributes of the
/// same type.
@immutable
class AutoFormatTextAttribute extends TextAttribute {
  /// Create an auto format text attribute.
  const AutoFormatTextAttribute(this.attribute);

  /// The wrapped attribute that this attribute will delegate to in [resolve].
  final TextAttribute attribute;

  @override
  SpanExpandRules get expandRules => SpanExpandRules.exclusive();

  @override
  TextAttributeValue resolve(BuildContext context) {
    return attribute.resolve(context);
  }
}

/// Signature for function that creates or gets a [TextAttribute] for a given
/// [RegExpMatch]. Used by [FormatRule].
typedef MatchToAttribute = TextAttribute? Function(RegExpMatch);

/// Gets the range in the text for a match.
typedef FormatIndexer = Range Function(RegExpMatch);

/// Rule that applies a [TextAttribute] to text that matches
/// a regex. Used by [AutoFormatter].
@immutable
class FormatRule {
  /// Create a format rule.
  const FormatRule(
    this.exp,
    this.matchToAttribute, [
    this.formatIndexer,
  ]);

  FormatRule.group(
    RegExp exp,
    int group,
    TextAttribute? Function(String) groupToAttribute,
  ) : this(
          exp,
          (m) => groupToAttribute(m.group(group)!),
          (m) => m.findGroupRange(group)!,
        );

  /// The regex that should be matched.
  final RegExp exp;

  /// Function that converts a regular expression match to an attribute.
  final MatchToAttribute matchToAttribute;

  /// Get the range of indices within the string for which formatting should be
  /// applied. Leave at null if the full match should be formatted.
  final FormatIndexer? formatIndexer;

  @override
  String toString() {
    return 'FormatRule<${exp.pattern}>';
  }
}

/// A collection of [FormatRule]s that can be applied to [AttributedText] using
/// [applyToString].
///
/// For automatic formatting see [AutoFormatter].
///
/// Attributes applied with a format ruleset are wrapped in an
/// [AutoFormatTextAttribute]. When serializing, make sure to delete or
/// transform these attributes, or provide a serializer for them.
class FormatRuleset {
  /// Create a format ruleset.
  const FormatRuleset(this.rules);

  /// Rules for formatting.
  final List<FormatRule> rules;

  /// Apply the formatting rules to [source] and return the resulting
  /// [AttributeSpanList].
  AttributeSpanList applyToString(AttributedText source,
      {bool clearPrevious = true}) {
    final text = source.text.string;
    var spans = source.spans;
    if (clearPrevious) {
      spans = spans.removeType<AutoFormatTextAttribute>();
    }

    for (final rule in rules) {
      final matches = rule.exp.allMatches(text);
      for (final match in matches) {
        // Zero-length spans are not allowed, so we filter out zero-length
        // matches.
        if (match.end == match.start) {
          continue;
        }

        final range =
            rule.formatIndexer?.call(match) ?? Range(match.start, match.end);

        // We have to do some index translation here because regex returns
        // UTF-16 character indices, but we use ECG (with the characters
        // package).

        final chars = CharacterRange.at(text, range.start, range.end);
        final start = chars.charactersBefore.length;
        final end = start + chars.currentCharacters.length;
        final innerAttr = rule.matchToAttribute(match);
        if (innerAttr != null) {
          final attribute = AutoFormatTextAttribute(innerAttr);
          final span = AttributeSpan(attribute, start, end);
          spans = spans.merge(span);
        }
      }
    }

    return spans;
  }

  /// Apply this ruleset to the given document and return the result.
  Document applyToDocument(Document document, {bool clearPrevious = true}) {
    return Document(
      document.paragraphs.map<Paragraph>(
        (p) {
          if (p is TextParagraphBase) {
            return p.withSpans(
              applyToString(p.attributedText, clearPrevious: clearPrevious),
            );
          }
          return p;
        },
      ),
    );
  }
}

/// Widget that automatically applies [TextAttribute]s to all
/// [TextParagraphController]s in a document based on [FormatRule]s.
///
/// The auto formatter is only a widget for convenience. It can be anywhere
/// in the widget tree.
///
/// Attributes applied with the auto formatter are wrapped in an
/// [AutoFormatTextAttribute]. When serializing, make sure to delete or
/// transform these attributes, or provide a serializer for them.
///
/// See [FormatRuleset] for a way to apply formatting attributes once.
class AutoFormatter extends TextParagraphListenerWidget {
  /// Create an auto formatter.
  AutoFormatter({
    Key? key,
    required this.controller,
    required List<FormatRule> rules,
    required this.child,
  })  : ruleset = FormatRuleset(rules),
        super(key: key);

  /// Create an auto formatter.
  const AutoFormatter.ruleset({
    Key? key,
    required this.controller,
    required this.ruleset,
    required this.child,
  }) : super(key: key);

  /// Document controller to apply formatting to.
  final DocumentController controller;

  /// Rules for formatting.
  final FormatRuleset ruleset;

  /// Child of this widget.
  final Widget child;

  @override
  _AutoFormatterState createState() => _AutoFormatterState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DocumentController>('controller', controller));
    properties.add(DiagnosticsProperty<FormatRuleset>('ruleset', ruleset));
  }
}

class _AutoFormatterState extends State<AutoFormatter>
    with TextParagraphListener {
  final Map<AttributedTextEditingController, String> _lastText = {};

  @override
  void initState() {
    super.initState();
    _autoFormatAll();
  }

  @override
  void onParagraphAdded(ParagraphAddedEvent event) {
    super.onParagraphAdded(event);
    final controller = event.controller;
    if (controller is TextParagraphControllerMixin) {
      _autoFormat(controller.textController);
    }
  }

  @override
  void onValueChanged(TextParagraphControllerMixin controller) {
    _autoFormat(controller.textController);
  }

  void _autoFormat(AttributedTextEditingController controller) {
    final previous = _lastText[controller];
    if (previous == controller.text) {
      return;
    }

    _lastText[controller] = controller.text;

    final formattedSpans =
        widget.ruleset.applyToString(controller.attributedText);
    controller.spans = formattedSpans;
  }

  void _autoFormatAll() {
    widget.controller.paragraphs
        .whereType<TextParagraphControllerMixin>()
        .forEach((c) => _autoFormat(c.textController));
  }

  @mustCallSuper
  void onParagraphRemoved(ParagraphRemovedEvent event) {
    super.onParagraphRemoved(event);
    final controller = event.controller;
    if (controller is TextParagraphControllerMixin) {
      _lastText.remove(controller);
    }
  }

  @override
  void didUpdateWidget(AutoFormatter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _lastText.clear();
    } else if (widget.ruleset != oldWidget.ruleset) {
      _autoFormatAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Provides extension methods related to auto formatting on [RegExpMatch].
extension AutoFormatRegExpMatchEx on RegExpMatch {
  /// Find the indices in the input string where a captured group starts and
  /// ends.
  ///
  /// This method is naive, in that it uses [String.indexOf] to find
  /// the group string within the match.
  Range? findGroupRange(int group) {
    final g = this.group(group);
    if (g == null) return null;

    final match = this.input.substring(start, end);
    final groupStart = start + match.indexOf(g);
    return Range(groupStart, groupStart + g.length);
  }
}
