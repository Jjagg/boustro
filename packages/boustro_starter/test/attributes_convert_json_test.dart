import 'dart:convert' show jsonEncode, jsonDecode;

import 'package:boustro_starter/boustro_starter.dart';
import 'package:boustro_starter/json.dart' as json_codec;
import 'package:boustro/convert_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final c = DocumentJsonCodec(
    attributes: [
      json_codec.bold,
      json_codec.italic,
      json_codec.strikethrough,
      json_codec.underline,
    ],
  );

  test('bold', () {
    final doc = (DocumentBuilder()
          ..line((b) => b
            ..start(boldAttribute)
            ..write('Hello, World!')))
        .build();
    final encoded = jsonEncode(c.encode(doc));
    expect(encoded,
        '{"paragraphs":[{"type":"text","text":"Hello, World!","spans":[{"type":"bold","end":13}]}]}');
    final rt = c.decode(jsonDecode(encoded));
    expect(rt, doc);
  });

  test('italic', () {
    final doc = (DocumentBuilder()
          ..line((b) => b
            ..start(italicAttribute)
            ..write('Hello, World!')))
        .build();
    final encoded = jsonEncode(c.encode(doc));
    expect(encoded,
        '{"paragraphs":[{"type":"text","text":"Hello, World!","spans":[{"type":"italic","end":13}]}]}');
    final rt = c.decode(jsonDecode(encoded));
    expect(rt, doc);
  });

  test('underline', () {
    final doc = (DocumentBuilder()
          ..line((b) => b
            ..start(underlineAttribute)
            ..write('Hello, World!')))
        .build();
    final encoded = jsonEncode(c.encode(doc));
    expect(encoded,
        '{"paragraphs":[{"type":"text","text":"Hello, World!","spans":[{"type":"underline","end":13}]}]}');
    final rt = c.decode(jsonDecode(encoded));
    expect(rt, doc);
  });

  test('strikethrough', () {
    final doc = (DocumentBuilder()
          ..line((b) => b
            ..start(strikethroughAttribute)
            ..write('Hello, World!')))
        .build();
    final encoded = jsonEncode(c.encode(doc));
    expect(encoded,
        '{"paragraphs":[{"type":"text","text":"Hello, World!","spans":[{"type":"strike","end":13}]}]}');
    final rt = c.decode(jsonDecode(encoded));
    expect(rt, doc);
  });
}
