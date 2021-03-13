import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

void main() {
  runApp(MaterialApp(
    title: 'flutter_spanned_controller',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/// A simple attribute that makes the spanned text bold.
class BoldAttribute extends TextAttribute {
  /// Determine whether text typed before/after the start/end
  /// of the span is included in the span.
  @override
  SpanExpandRules get expandRules => SpanExpandRules(
        ExpandRule.inclusive,
        ExpandRule.inclusive,
      );

  @override
  TextAttributeValue resolve(BuildContext context) {
    return const TextAttributeValue(
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final String quote = 'Pack my box with five dozen liquor jugs';
  late final SpannedTextEditingController controller =
      SpannedTextEditingController(
    text: '"$quote" is the better panagram.',
    spans: SpanList([AttributeSpan(BoldAttribute(), 1, quote.length + 1)]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_spanned_controller'),
      ),
      body: Center(
        // We pass the controller so it can work its magic and apply the text
        // span.
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(controller: controller),
        ),
      ),
    );
  }
}
