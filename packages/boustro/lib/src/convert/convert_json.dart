import 'dart:convert';

import 'package:boustro/boustro.dart';
import 'package:built_collection/built_collection.dart';

// Document JSON:
// {
//   "paragraphs": [
//     {
//       "type":"line",
//       "text": <text>?,
//       "modifiers": [
//         {"type": <type>, "value": <value>?}
//       ]?,
//       "spans": [
//         {
//           "type": <type>,
//           "value": <value>?,
//           "start": <start>,
//           "end": <end>,
//       ]?
//     } OR
//     {
//       "type": "<paragraph type>",
//       "value": <json serialized value>?
//     }
//   ]
// }

/// Rules for encoding and decoding a boustro component.
abstract class ComponentCodec<T> {
  /// Create a codec for a component that needs to serialize state.
  const ComponentCodec.stateful({
    required this.typeStr,
    required T Function(Object?) decode,
    required Object? Function(T) encode,
  })  : _decode = decode,
        _encode = encode,
        _create = null;

  /// Create a codec for a component that does not have state.
  const ComponentCodec.stateless({
    required this.typeStr,
    required T Function() create,
  })  : _create = create,
        _decode = null,
        _encode = null;

  final T Function(Object?)? _decode;
  final Object? Function(T)? _encode;
  final T Function()? _create;

  /// String identifier used to find the codec to deserialize a component with.
  final String typeStr;

  /// Type of the component that this codec can encode/decode.
  Type get type => T;

  /// Decode the serialized state of a component to a [T].
  T decode(Object? value) {
    return _decode?.call(value) ?? _create!();
  }

  /// Encode a component's state.
  Object? encode(T value) {
    return _encode?.call(value);
  }
}

/// Component codec for [TextAttribute]s.
class TextAttributeCodec<T extends TextAttribute> extends ComponentCodec<T> {
  /// Create a text attribute codec for a stateful text attribute.
  const TextAttributeCodec.stateful({
    required String typeStr,
    required Object? Function(T) encode,
    required T Function(Object?) decode,
  }) : super.stateful(typeStr: typeStr, encode: encode, decode: decode);

  /// Create a text attribute codec for a stateless text attribute.
  const TextAttributeCodec.stateless({
    required String typeStr,
    required T Function() create,
  }) : super.stateless(typeStr: typeStr, create: create);
}

/// Component codec for [Paragraph]s.
class ParagraphCodec<T extends Paragraph> extends ComponentCodec<T> {
  /// Create a paragraph codec for a stateful paragraph.
  const ParagraphCodec.stateful({
    required String typeStr,
    required Object? Function(T) encode,
    required T Function(Object?) decode,
  }) : super.stateful(typeStr: typeStr, encode: encode, decode: decode);

  /// Create a paragraph codec for a stateless paragraph.
  const ParagraphCodec.stateless({
    required String typeStr,
    required T Function() create,
  }) : super.stateless(typeStr: typeStr, create: create);
}

/// Convert a document to or from JSON.
class DocumentJsonCodec extends Codec<Document, dynamic> {
  /// Create a codec to convert a document to or from JSON with codecs for
  /// attributes and paragraphs that are supported for conversion.
  factory DocumentJsonCodec({
    Iterable<TextAttributeCodec> attributes = const [],
    Iterable<ParagraphCodec> paragraphs = const [],
  }) {
    final decoder = _JsonDecoder(
      attributeDecoders:
          {for (final ac in attributes) ac.typeStr: ac.decode}.build(),
      paragraphDecoders:
          {for (final lc in paragraphs) lc.typeStr: lc.decode}.build(),
    );
    final encoder = _JsonEncoder(
      attributes: {for (final attr in attributes) attr.type: attr}.build(),
      paragraphs: {for (final p in paragraphs) p.type: p}.build(),
    );
    return DocumentJsonCodec._(decoder, encoder);
  }

  DocumentJsonCodec._(this._decoder, this._encoder);

  final _JsonDecoder _decoder;
  final _JsonEncoder _encoder;

  @override
  Converter<dynamic, Document> get decoder => _decoder;

  @override
  Converter<Document, dynamic> get encoder => _encoder;
}

const String _paragraphsKey = 'paragraphs';

const String _lineType = 'text';

const String _textKey = 'text';
const String _spansKey = 'spans';

const String _typeKey = 'type';
const String _valueKey = 'value';

const String _startKey = 'start';
const String _endKey = 'end';

class _JsonDecoder extends Converter<dynamic, Document> {
  const _JsonDecoder({
    required this.attributeDecoders,
    required this.paragraphDecoders,
  });

  final BuiltMap<String, TextAttribute Function(Object?)> attributeDecoders;
  final BuiltMap<String, Paragraph Function(Object?)> paragraphDecoders;

  @override
  Document convert(dynamic input) {
    final root =
        _expectProperties(() => 'Root object', input, [_paragraphsKey]);
    final paragraphs = _expectProperty<List<dynamic>>(
        () => 'Root object', root, _paragraphsKey);
    final decodedParagraphs = <Paragraph>[];

    for (final p in paragraphs) {
      if (p is! Map<String, dynamic>) {
        throw const FormatException('paragraph items must be objects.');
      }

      final type = p[_typeKey] as Object?;

      if (type == null) {
        throw const FormatException('Type must be provided for paragraph.');
      }

      if (type == _lineType) {
        final lineMap = _expectProperties(
          () => _paragraphsKey,
          p,
          [_typeKey, _textKey, _spansKey],
        );
        final text = _expectProperty<String?>(
            () => '$_paragraphsKey.$_textKey', lineMap, _textKey);
        final spans = _expectProperty<List<dynamic>?>(
          () => '$_paragraphsKey.$_spansKey',
          lineMap,
          _spansKey,
        )?.map(_parseSpan);

        final line = TextParagraph(
          text ?? '',
          spans,
        );
        decodedParagraphs.add(line);
      } else {
        final decoder = paragraphDecoders[type];
        if (decoder == null) {
          throw FormatException('Missing decoder for paragraph of type $type.');
        }
        final value = p[_valueKey] as Object?;
        final paragraph = decoder(value);

        decodedParagraphs.add(paragraph);
      }
    }

    return Document(decodedParagraphs);
  }

  AttributeSpan _parseSpan(dynamic map) {
    final spanMap = _expectProperties(
      () => '$_paragraphsKey.$_spansKey',
      map,
      [_typeKey, _valueKey, _startKey, _endKey],
    );

    final attribute = _parseTypeValue(
      () => '$_paragraphsKey.$_spansKey',
      spanMap,
      attributeDecoders,
    );
    final start = _expectProperty<int?>(
          () => '$_paragraphsKey.$_spansKey.$_startKey',
          spanMap,
          _startKey,
        ) ??
        0;
    final end = _expectProperty<int?>(
          () => '$_paragraphsKey.$_spansKey.$_endKey',
          spanMap,
          _endKey,
        ) ??
        maxSpanLength;

    return AttributeSpan(attribute, start, end);
  }
}

class _JsonEncoder extends Converter<Document, dynamic> {
  const _JsonEncoder({
    required this.attributes,
    required this.paragraphs,
  });

  final BuiltMap<Type, TextAttributeCodec> attributes;
  final BuiltMap<Type, ParagraphCodec> paragraphs;

  @override
  dynamic convert(Document input) {
    return <String, dynamic>{
      'paragraphs': [
        for (final p in input.paragraphs) _encodeParagraph(p),
      ]
    };
  }

  Map<String, Object> _encodeParagraph(Paragraph p) {
    if (p is TextParagraph) {
      final t = p.attributedText;
      return <String, Object>{
        _typeKey: _lineType,
        if (t.text.isNotEmpty) _textKey: p.attributedText.text.string,
        if (t.spans.iter.isNotEmpty)
          _spansKey: t.spans.iter.map<Object>(_encodeSpan).toList(),
      };
    }
    return _encodeWithTypeMap('paragraph', paragraphs, p);
  }

  Object _encodeSpan(AttributeSpan span) {
    final attr = _encodeWithTypeMap('attribute', attributes, span.attribute);
    return <String, dynamic>{
      ...attr,
      if (span.start != 0) _startKey: span.start,
      if (span.end != maxSpanLength) _endKey: span.end,
    };
  }
}

T _expectProperty<T>(
  String Function() propertyFunc,
  Map<String, dynamic> map,
  String key,
) {
  final dynamic value = map[key];
  if (value is! T) {
    throw FormatException(
        '${propertyFunc()} must be of type $T, but is ${value.runtimeType}.');
  }
  return value;
}

Map<String, dynamic> _expectProperties(
  String Function() propertyFunc,
  dynamic map,
  List<String> fields,
) {
  if (map is! Map<String, dynamic> ||
      !map.keys.every((key) => fields.contains(key))) {
    throw FormatException(
        '${propertyFunc()} must be an object with fields $fields.');
  }
  return map;
}

/// Handles the common pattern where a JSON object
/// '{"type": <type>, "value": <value>?}' is deserialized with a `decoderMap`
/// where `decoderMap[type]` can decode `value`.
T _parseTypeValue<T>(
  String Function() property,
  Map<String, dynamic> map,
  BuiltMap<String, T Function(Object?)> decoderMap,
) {
  final type =
      _expectProperty<String>(() => '${property()}.$_typeKey', map, _typeKey);
  final decoder = decoderMap[type];
  if (decoder == null) {
    throw FormatException('Missing decoder for $T of type $type.');
  }
  final value = map[_valueKey] as Object?;
  return decoder(value);
}

Map<String, Object> _encodeWithTypeMap<T>(
  String typeMapKind,
  BuiltMap<Type, ComponentCodec<dynamic>> encoderMap,
  T value, {
  String typeKey = _typeKey,
}) {
  final encoder = encoderMap[value.runtimeType];
  if (encoder == null) {
    throw JsonEncoderException._(
        'Missing encoder for $typeMapKind of type ${value.runtimeType}.');
  }

  final encodedValue = encoder.encode(value);
  return <String, Object>{
    typeKey: encoder.typeStr,
    if (encodedValue != null) _valueKey: encodedValue,
  };
}

/// Exception thrown when json encoding fails.
class JsonEncoderException implements Exception {
  const JsonEncoderException._(this.message);

  /// Message of this exception.
  final String message;
}
