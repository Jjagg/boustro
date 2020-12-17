// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
import 'dart:convert';

import 'package:boustro/convert_delta.dart';
import 'package:flutter_test/flutter_test.dart';

const doc3 =
    r'''[{"insert":"Project Pura"},{"insert":"\n","attributes":{"header":1}},{"insert":"We've just launched the Project Pura app!","attributes":{"italic":true}},{"insert":"\n"},{"insert":{"image":"assets/logo128.png"}},{"insert":"\n"},{"insert":"Photo by Hiroyuki Takeda.","attributes":{"italic":true}},{"insert":"\nZefyr is currently in "},{"insert":"early preview","attributes":{"bold":true}},{"insert":". If you have a feature request or found a bug, please file it at the "},{"insert":"issue tracker","attributes":{"link":"https://github.com/memspace/zefyr/issues"}},{"insert":'''
    r'".\nDocumentation"},{"insert":"\n","attributes":{"header":3}},{"insert":"Quick Start","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/quick_start.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Data Format and Document Model","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/data_and_document.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Style Attributes","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/attr'
    r'ibutes.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Heuristic Rules","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/heuristics.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"FAQ","attributes":{"link":"https://github.com/memspace/zefyr/blob/master/doc/faq.md"}},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"header":2}},{"insert":"Zefyr’s rich text editor is built with simplicity and fle'
    r'xibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nMarkdown inspired semantics"},{"insert":"\n","attributes":{"header":2}},{"insert":"Ever needed to have a heading line inside of a quote block, like this:\nI’m a Markdown heading"},{"insert":"\n","attributes":{"blockquote":true,"header":3}},{"insert":"And I’m a regular paragraph"},{"insert":"\n","attributes":{"blockquote":true}}]';

// TODO We don't want strong mode implicit-dynamic here, but I don't think
//      the analyzer lets us disable it for tests.

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
  final boldCodec = deltaBoolAttributeCodec(
    'bold',
    bold,
    InsertBehavior.exclusive,
    InsertBehavior.inclusive,
  );

  final deltaConverter = BoustroDocumentDeltaConverter([boldCodec], []);

  final createBold = (int start, int end) => AttributeSpan(
        bold,
        start,
        end,
        InsertBehavior.exclusive,
        InsertBehavior.inclusive,
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
        BoustroLine(
          text: 'Hello, World!',
          spans: SpanList([createBold(0, 5)]),
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
        BoustroLine(
          text: 'Hello, World!',
          spans: SpanList([createBold(0, 5)]),
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
          BoustroLine(
            text: 'Hello, World!',
            spans: SpanList([createBold(0, 5)]),
          ));
      expect(
        doc.paragraphs[1],
        BoustroLine(text: '', spans: SpanList()),
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
          BoustroLine(
            text: 'Hello, World!',
            spans: SpanList([createBold(0, 5)]),
          ));
      expect(
        doc.paragraphs[1],
        BoustroLine(
          text: 'Hello, World!',
          spans: SpanList([createBold(5, 13)]),
        ),
      );
    });
  });
}

class TestAttribute extends TextAttribute {
  @override
  TextAttributeValue resolve(AttributeThemeData theme) {
    throw UnimplementedError();
  }
}
