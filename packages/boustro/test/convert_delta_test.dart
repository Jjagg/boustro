// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
import 'dart:convert';

import 'package:boustro/convert_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const opDecoder = OpJsonCodec();
  group('delta json decoder', () {
    test('simple', () {
      const doc1 = r'[{"insert":"Hello, World."},{"insert":"\n"}]';
      final dynamic jsonOps = jsonDecode(doc1);
      final dynamic ops = jsonOps.map(opDecoder.decode);
      expect(ops, [InsertOp('Hello, World.'), InsertOp('\n')]);
    });

    test('attribs', () {
      const doc2 =
          r'[{"insert":"Welcome"},{"insert":"\n","attributes":{"header":1}},{"insert":"Welcome to our platform, Project Pura! 💚"},{"insert":"\n"},'
          r'{"insert":"Check out "},{"insert":"#welcome","attributes":{"tag":true}},{"insert":" for some info on how to use the platform 😎"},{"insert":"\n"}]';
      final dynamic jsonOps = jsonDecode(doc2);
      final dynamic ops = jsonOps.map(opDecoder.decode);
      expect(ops, [
        InsertOp('Welcome'),
        InsertOp('\n', attributes: <String, dynamic>{'header': 1}),
        InsertOp('Welcome to our platform, Project Pura! 💚'),
        InsertOp('\n'),
        InsertOp('Check out '),
        InsertOp('#welcome', attributes: <String, dynamic>{'tag': true}),
        InsertOp(' for some info on how to use the platform 😎'),
        InsertOp('\n')
      ]);
    });

    test('object embed', () {
      const docObj =
          '''[{"insert":{"image":{"path": "some_image", "alt": "some alt text"}}}]''';
      final dynamic jsonOps = jsonDecode(docObj);
      final dynamic ops = jsonOps.map(opDecoder.decode);
      // '''{"insert":{"image":{"path": "some_image", "alt": "some alt text"}}}''';
      final objOp = ops.first as InsertObjectOp;
      expect(objOp.type, 'image');
      expect(
          objOp.value.asMap(), {'path': 'some_image', 'alt': 'some alt text'});
      expect(objOp.attributes, isEmpty);
    });
  });

  final bold = TestAttribute();
  final boldCodec = deltaBoolAttributeCodec('bold', bold);

  final deltaConverter = DocumentDeltaConverter([boldCodec], []);

  final createBold = (int start, int end) => AttributeSpan(
        bold,
        start,
        end,
      );

  group('op to boustro document converter', () {
    test('hello world', () {
      final ops = [
        InsertOp('Hello', attributes: <String, dynamic>{'bold': true}),
        InsertOp(', World!'),
      ];
      final doc = deltaConverter.decode(ops);
      expect(doc.paragraphs.length, 1);
      expect(
        doc.paragraphs[0],
        LineParagraph(
          text: 'Hello, World!',
          spans: AttributeSpanList([createBold(0, 5)]),
        ),
      );
    });

    test('hello world newline', () {
      final ops = [
        InsertOp('Hello', attributes: <String, dynamic>{'bold': true}),
        InsertOp(', World!\n'),
      ];
      final doc = deltaConverter.decode(ops);
      expect(doc.paragraphs.length, 1);
      expect(
        doc.paragraphs[0],
        LineParagraph(
          text: 'Hello, World!',
          spans: AttributeSpanList([createBold(0, 5)]),
        ),
      );
    });

    test('hello world newline x2', () {
      final ops = [
        InsertOp('Hello', attributes: <String, dynamic>{'bold': true}),
        InsertOp(', World!\n\n'),
      ];
      final doc = deltaConverter.decode(ops);
      expect(doc.paragraphs.length, 2);
      expect(
          doc.paragraphs[0],
          LineParagraph(
            text: 'Hello, World!',
            spans: AttributeSpanList([createBold(0, 5)]),
          ));
      expect(
        doc.paragraphs[1],
        LineParagraph(text: '', spans: AttributeSpanList.empty),
      );
    });

    test('hello world formatted x2', () {
      final ops = [
        InsertOp('Hello', attributes: <String, dynamic>{'bold': true}),
        InsertOp(', World!'),
        InsertOp('\n'),
        InsertOp('Hello'),
        InsertOp(', World!', attributes: <String, dynamic>{'bold': true}),
      ];
      final doc = deltaConverter.decode(ops);
      expect(doc.paragraphs.length, 2);
      expect(
          doc.paragraphs[0],
          LineParagraph(
            text: 'Hello, World!',
            spans: AttributeSpanList([createBold(0, 5)]),
          ));
      expect(
        doc.paragraphs[1],
        LineParagraph(
          text: 'Hello, World!',
          spans: AttributeSpanList([createBold(5, 13)]),
        ),
      );
    });
  });
}

class TestAttribute extends TextAttribute {
  @override
  TextAttributeValue resolve(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  SpanExpandRules get expandRules =>
      SpanExpandRules(ExpandRule.exclusive, ExpandRule.inclusive);
}
