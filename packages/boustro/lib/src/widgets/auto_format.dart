import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../document.dart';
import '../spans/attribute_span.dart';
import '../spans/spanned_string.dart';
import '../spans/spanned_text_controller.dart';
import 'document_controller.dart';

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
typedef MatchToAttribute = TextAttribute Function(RegExpMatch);

/// Rule that applies a [TextAttribute] to text that matches
/// a regex. Used by [AutoFormatter].
@immutable
class FormatRule {
  /// Create a format rule.
  const FormatRule(this.exp, this.matchToAttribute);

  /// The regex that should be matched.
  final RegExp exp;

  /// Function that converts a regular expression match to an attribute.
  final MatchToAttribute matchToAttribute;

  @override
  String toString() {
    return 'FormatRule<${exp.pattern}>';
  }
}

/// A collection of [FormatRule]s that can be applied to a [SpannedString] using
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
  AttributeSpanList applyToString(SpannedString source,
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

        // We have to do some index translation here because regex returns
        // UTF-16 character indices, but we use ECG (with the characters
        // package).

        final chars = CharacterRange.at(text, match.start, match.end);
        final start = chars.charactersBefore.length;
        final end = start + chars.currentCharacters.length;
        final attribute = AutoFormatTextAttribute(rule.matchToAttribute(match));
        final span = AttributeSpan(attribute, start, end);
        spans = spans.merge(span);
      }
    }

    return spans;
  }

  /// Apply this ruleset to the given document and return the result.
  Document applyToDocument(Document document, {bool clearPrevious = true}) {
    return Document(
      document.paragraphs.map(
        (p) => p.match(
          line: (l) {
            return l.copyWith(
              spans: applyToString(l.spannedText, clearPrevious: clearPrevious),
            );
          },
          embed: (e) => e,
        ),
      ),
    );
  }
}

/// Widget that automatically applies [TextAttribute]s to a [DocumentController]
/// based on [FormatRule]s.
///
/// The auto formatter is only a widget for convenience. It can be anywhere
/// in the widget tree.
///
/// Attributes applied with the auto formatter are wrapped in an
/// [AutoFormatTextAttribute]. When serializing, make sure to delete or
/// transform these attributes, or provide a serializer for them.
class AutoFormatter extends StatefulWidget {
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

class _AutoFormatterState extends State<AutoFormatter> {
  final Map<SpannedTextEditingController, String> _lastText = {};

  StreamSubscription<LineValueChangedEvent>? _lineValueChangedSubscription;

  @override
  void initState() {
    super.initState();
    _lineValueChangedSubscription =
        widget.controller.onLineValueChanged.listen(_handleLineValueChanged);
    widget.controller.addListener(_handleParagraphsChanged);
  }

  void _handleLineValueChanged(LineValueChangedEvent event) {
    _autoFormat(event.state.controller);
  }

  void _handleParagraphsChanged() {
    for (final line in widget.controller.paragraphs.whereType<LineState>()) {
      _autoFormat(line.controller);
    }
  }

  @override
  void dispose() {
    _lineValueChangedSubscription?.cancel();
    widget.controller.removeListener(_handleParagraphsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _autoFormat(SpannedTextEditingController controller) {
    final previous = _lastText[controller];
    if (previous == controller.text) {
      return;
    }

    _lastText[controller] = controller.text;

    final formattedSpans =
        widget.ruleset.applyToString(controller.spannedString);
    controller.spans = formattedSpans;
  }
}
