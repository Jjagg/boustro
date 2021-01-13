import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

import 'document_controller.dart';

@immutable
class _AutoFormatTextAttribute extends TextAttribute {
  const _AutoFormatTextAttribute(this.attribute);

  final TextAttribute attribute;

  @override
  SpanExpandRules get expandRules =>
      SpanExpandRules(ExpandRule.exclusive, ExpandRule.exclusive);

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

  @override
  void initState() {
    super.initState();

    // TODO We should be a little more conservative in calling _autoFormat
    // for performance reasons, but we'll need to do some bookkeeping or expose
    // more granular events in DocumentController.
    widget.controller.onLineValueChanged.listen((event) {
      _autoFormat(event.controller);
    });
    widget.controller.addListener(() {
      for (final line in widget.controller.paragraphs.whereType<LineState>()) {
        _autoFormat(line.controller);
      }
    });
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
    spans = spans.removeType<_AutoFormatTextAttribute>();

    for (final rule in widget.rules) {
      // Check for new matches.
      final matches = rule.exp.allMatches(text);
      for (final match in matches) {
        if (match.end - match.start == 0) {
          continue;
        }

        final chars = CharacterRange.at(text, match.start, match.end);
        final start = chars.charactersBefore.length;
        final end = start + chars.currentCharacters.length;
        final attribute =
            _AutoFormatTextAttribute(rule.matchToAttribute(match));
        final span = AttributeSpan(attribute, start, end);
        spans = spans.merge(span);
      }
    }

    controller.spans = spans;
  }
}
