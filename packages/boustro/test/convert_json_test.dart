// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
import 'dart:convert';

import 'package:boustro/convert_json.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codec = DocumentJsonCodec(
    attributes: [testAttributeCodec],
    paragraphs: [testParagraphCodec],
  );

  group('json encoder', () {
    test('simple roundtrip', () {
      final doc = Document(<Paragraph>[
        TextParagraph('Hello, World!'),
      ]);

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(
          rawJson, '{"paragraphs":[{"type":"text","text":"Hello, World!"}]}');
      final decoded = codec.decode(json);

      expect(decoded, doc);
    });

    test('spans roundtrip', () {
      final doc = Document(<Paragraph>[
        TextParagraph(
          'Hello, World!',
          [AttributeSpan(TestAttribute(), 3, 7)],
        ),
      ]);

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(rawJson,
          '{"paragraphs":[{"type":"text","text":"Hello, World!","spans":[{"type":"test","start":3,"end":7}]}]}');
      final decoded = codec.decode(json);
      expect(decoded, doc);
    });

    test('paragraph roundtrip', () {
      final doc = Document(<Paragraph>[
        TestParagraph(),
      ]);

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(rawJson, '{"paragraphs":[{"type":"test"}]}');
      final decoded = codec.decode(json);
      expect(decoded, doc);
    });
  });
}

final testAttributeCodec = TextAttributeCodec<TestAttribute>.stateless(
  typeStr: 'test',
  create: () => TestAttribute(),
);

final testParagraphCodec = ParagraphCodec<TestParagraph>.stateless(
  typeStr: 'test',
  create: () => TestParagraph(),
);

class TestAttribute extends TextAttribute with EquatableMixin {
  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextAttributeValue resolve(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [];
}

class TestParagraph extends Paragraph with EquatableMixin {
  @override
  List<Object?> get props => [];

  @override
  Widget buildView(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  ParagraphController createController() {
    throw UnimplementedError();
  }
}
