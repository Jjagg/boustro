import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

const bold = BoldAttribute.value;

class _MyAppState extends State<MyApp> {
  late final SpannedTextController _controller = //TextEditingController();
      SpannedTextController()
        ..value = TextEditingValue(text: 'Hello, World!')
        ..addSpan(
          AttributeSpan(
            bold,
            TextRange(start: 0, end: 5),
            InsertBehavior.exclusive,
            InsertBehavior.inclusive,
          ),
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Boustro'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.black87, fontSize: 32),
                child: Builder(
                  builder: (context) => TextField(
                    controller: _controller,
                    maxLines: null,
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
            Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.addAttributeListener(bold),
                builder: (context, isBold, _) => RaisedButton(
                  onPressed: () {
                    _controller.toggleAttribute(
                      bold,
                      InsertBehavior.exclusive,
                      InsertBehavior.inclusive,
                    );
                  },
                  child: Text(isBold ? 'Bold on' : 'Bold off'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
