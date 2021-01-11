// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
import 'dart:convert';

import 'package:boustro/convert_json.dart';
import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codec = DocumentJsonCodec(
    attributes: [testAttributeCodec],
    lineModifiers: [testLineModCodec],
    embeds: [testEmbedCodec],
  );

  group('json encoder', () {
    test('simple roundtrip', () {
      final doc = Document(<Paragraph>[
        LineParagraph(text: 'Hello, World!'),
      ].build());

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(
          rawJson, '{"paragraphs":[{"type":"line","text":"Hello, World!"}]}');
      final decoded = codec.decode(json);

      expect(decoded, doc);
    });

    test('spans roundtrip', () {
      final doc = Document(<Paragraph>[
        LineParagraph(
          text: 'Hello, World!',
          spans: SpanList([AttributeSpan(TestAttribute(), 3, 7)]),
        ),
      ].build());

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(rawJson,
          '{"paragraphs":[{"type":"line","text":"Hello, World!","spans":[{"type":"test","start":3,"end":7}]}]}');
      final decoded = codec.decode(json);
      expect(decoded, doc);
    });

    test('linemod roundtrip', () {
      final doc = Document(<Paragraph>[
        LineParagraph(
          text: 'Hello, World!',
          modifiers: [TestLineMod()],
        ),
      ].build());

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(rawJson,
          '{"paragraphs":[{"type":"line","text":"Hello, World!","mods":[{"type":"test"}]}]}');
      final decoded = codec.decode(json);
      expect(decoded, doc);
    });

    test('embed roundtrip', () {
      final doc = Document(<Paragraph>[
        TestEmbed(),
      ].build());

      final dynamic json = codec.encode(doc);
      final rawJson = jsonEncode(json);
      expect(rawJson, '{"paragraphs":[{"type":"embed","embed":"test"}]}');
      final decoded = codec.decode(json);
      expect(decoded, doc);
    });
  });
}

final testAttributeCodec = TextAttributeCodec<TestAttribute>.stateless(
  typeStr: 'test',
  create: () => TestAttribute(),
);

final testLineModCodec = LineModifierCodec<TestLineMod>.stateless(
  typeStr: 'test',
  create: () => TestLineMod(),
);

final testEmbedCodec = ParagraphEmbedCodec<TestEmbed>.stateless(
  typeStr: 'test',
  create: () => TestEmbed(),
);

class TestAttribute extends TextAttribute with EquatableMixin {
  @override
  SpanExpandRules get expandRules => SpanExpandRules.after();

  @override
  TextAttributeValue resolve(AttributeThemeData theme) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [];
}

class TestLineMod extends LineModifier with EquatableMixin {
  @override
  Widget modify(BuildContext context, Widget child) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [];
}

class TestEmbed extends ParagraphEmbed with EquatableMixin {
  @override
  List<Object?> get props => [];

  @override
  ParagraphEmbedController createController() {
    throw UnimplementedError();
  }

  @override
  Widget createView(BuildContext context) {
    throw UnimplementedError();
  }
}
