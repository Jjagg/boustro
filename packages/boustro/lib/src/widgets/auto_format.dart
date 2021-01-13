import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

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

/// Widget that automatically applies [TextAttribute]s to a [DocumentController]
/// based on [FormatRule]s.
///
/// The auto formatter is only a widget for convenience. It can be anywhere
/// in the widget tree.
class AutoFormatter extends StatefulWidget {
  /// Create an auto formatter.
  const AutoFormatter({
    Key? key,
    required this.controller,
    required this.rules,
    required this.child,
  }) : super(key: key);

  /// Document controller to apply formatting to.
  final DocumentController controller;

  /// Rules for formatting.
  final List<FormatRule> rules;

  /// Child of this widget.
  final Widget child;

  @override
  _AutoFormatterState createState() => _AutoFormatterState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DocumentController>('controller', controller));
    properties.add(IterableProperty<FormatRule>('rules', rules));
  }
}

class _AutoFormatterState extends State<AutoFormatter> {
  final Map<SpannedTextEditingController, String> _lastText = {};

  late final StreamSubscription<LineValueChangedEvent>
      _lineValueChangedSubscription =
      widget.controller.onLineValueChanged.listen(_handleLineValueChanged);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleParagraphsChanged);
  }

  void _handleLineValueChanged(LineValueChangedEvent event) {
    _autoFormat(event.controller);
  }

  void _handleParagraphsChanged() {
    for (final line in widget.controller.paragraphs.whereType<LineState>()) {
      _autoFormat(line.controller);
    }
  }

  @override
  void dispose() {
    _lineValueChangedSubscription.cancel();
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

    final text = controller.text;
    var spans = controller.spans;
    spans = spans.removeType<AutoFormatTextAttribute>();

    for (final rule in widget.rules) {
      final matches = rule.exp.allMatches(text);
      for (final match in matches) {
        // Zero-length spans are not allowed, so we filter out zero-length
        // matches.
        if (match.end == match.start) {
          continue;
        }

        final chars = CharacterRange.at(text, match.start, match.end);
        final start = chars.charactersBefore.length;
        final end = start + chars.currentCharacters.length;
        final attribute =
            AutoFormatTextAttribute(rule.matchToAttribute(match));
        final span = AttributeSpan(attribute, start, end);
        spans = spans.merge(span);
      }
    }

    controller.spans = spans;
  }
}
