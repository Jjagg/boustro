import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:collection/collection.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../document.dart';
import 'convert.dart';
import 'ops.dart';

// BoustroDocument-Op codec

/// Rules for encoding and decoding a [TextAttribute] to and from a Quill
/// delta attribute.
@immutable
class TextAttributeDeltaCodec {
  /// Create a text text attribute codec for Quill delta conversion.
  const TextAttributeDeltaCodec({
    required this.key,
    required this.decoder,
    required this.insertBehavior,
    required this.appliesTo,
    required this.encoder,
  });

  /// Key of the [TextAttribute]. Identifies the type of the attribute.
  final String key;

  /// Decode the attribute value to a [TextAttribute].
  final Converter<dynamic, TextAttribute> decoder;

  /// Insert behavior to use when decoding an attribute to a [AttributeSpan].
  final FullInsertBehavior insertBehavior;

  /// Should return true if this codec applies to the given [TextAttribute].
  final bool Function(TextAttribute) appliesTo;

  /// Encoder for a [TextAttribute] value.
  final Converter<TextAttribute, Object> encoder;
}

/// Function that decodes an embed.
typedef EmbedDecoder = Object Function(Map<String, dynamic>);

/// Function that encodes an embed.
typedef EmbedEncoder = Map<String, dynamic> Function(Object);

/// Codec that can encode/decode the value of the embed with matching key.
@immutable
class EmbedCodec {
  /// Create an embed codec.
  const EmbedCodec(this.key, this.decoder, this.encoder);

  /// Identifies the type of the embed. See [ParagraphEmbedBuilder.type].
  final String key;

  /// Decoder for the embed value.
  final EmbedDecoder decoder;

  /// Encoder for the embed value.
  final EmbedEncoder encoder;
}

/// Convenience function to create a codec for a [TextAttribute] with a boolean
/// value.
///
/// Useful for toggleable attributes like bold or italic.
TextAttributeDeltaCodec deltaBoolAttributeCodec(
  String key,
  TextAttribute instance,
  InsertBehavior startBehavior,
  InsertBehavior endBehavior,
) {
  return TextAttributeDeltaCodec(
    key: key,
    decoder: ClosureConverter<dynamic, TextAttribute>((dynamic v) {
      if (v is! bool) {
        throw FormatException(
            'Expected attribute of type bool, but was ${v.runtimeType}');
      }
      if (!v) {
        throw const FormatException(
            'Boolean attributes should only be serialized when their value is true.');
      }
      return instance;
    }),
    insertBehavior: FullInsertBehavior(startBehavior, endBehavior),
    appliesTo: (t) => t.runtimeType == instance.runtimeType,
    encoder: ClosureConverter((_) => true),
  );
}

/// Convert a boustro document to or from a list of insert operations in Quill's
/// delta format.
class BoustroDocumentDeltaConverter extends Codec<BoustroDocument, List<Op>> {
  /// Create a delta converter
  BoustroDocumentDeltaConverter(
    List<TextAttributeDeltaCodec> attributeCodecs,
    List<EmbedCodec> embedCodec,
  )   : attributeDecoders = {for (final c in attributeCodecs) c.key: c},
        attributeEncoder = _createEncoder(attributeCodecs),
        embedDecoders = {for (final c in embedCodec) c.key: c.decoder},
        embedEncoders = {for (final c in embedCodec) c.key: c.encoder};

  static Object? Function(TextAttribute attribute) _createEncoder(
    List<TextAttributeDeltaCodec> attributeCodecs,
  ) {
    return (attr) => attributeCodecs
        .firstWhereOrNull((c) => c.appliesTo(attr))
        ?.encoder
        .convert(attr);
  }

  /// Maps string keys to matching attribute codecs.
  final Map<String, TextAttributeDeltaCodec> attributeDecoders;

  /// Maps embed keys to their decoder.
  final Map<String, EmbedDecoder> embedDecoders;

  /// Converts attributes to their value as a Quill delta attribute.
  final Object? Function(TextAttribute) attributeEncoder;

  /// Maps embed keys to their encoder.
  final Map<String, EmbedDecoder> embedEncoders;

  @override
  Converter<List<Op>, BoustroDocument> get decoder =>
      BoustroDocumentDeltaDecoder(attributeDecoders, embedDecoders);

  @override
  Converter<BoustroDocument, List<Op>> get encoder =>
      BoustroDocumentDeltaEncoder(attributeEncoder, embedEncoders);
}

/// Encodes a boustro document to a list of Quill delta insert operations.
class BoustroDocumentDeltaEncoder extends Converter<BoustroDocument, List<Op>> {
  /// Create an encoder.
  const BoustroDocumentDeltaEncoder(
    this.attributeEncoder,
    this.embedEncoders,
  );

  /// Converts attributes to their value as a Quill delta attribute.
  final Object? Function(TextAttribute attribute) attributeEncoder;

  /// Maps embed keys to their encoder.
  final Map<String, EmbedDecoder> embedEncoders;

  @override
  List<Op> convert(BoustroDocument input) {
    throw UnimplementedError();
  }
}

/// Convert a list of Quill delta format insert operations to a boustro
/// document.
///
/// Throws [ArgumentError] when an attribute is encountered with no entry in
/// [attributeCodecs].
class BoustroDocumentDeltaDecoder extends Converter<List<Op>, BoustroDocument> {
  /// Create a decoder.
  const BoustroDocumentDeltaDecoder(
    this.attributeCodecs,
    this.embedDecoders,
  );

  /// Maps string keys to matching attribute codecs.
  final Map<String, TextAttributeDeltaCodec> attributeCodecs;

  /// Maps embed keys to their decoder.
  final Map<String, EmbedDecoder> embedDecoders;

  @override
  BoustroDocument convert(List<Op> input) {
    // First group or split ops by lines (\n) because each line maps to a
    // BoustroParagraph.
    final paragraphs = <BoustroParagraph>[];
    for (final line in _groupByLines(input)) {
      final first = line.ops.firstOrNull;
      if (first is InsertObjectOp) {
        assert(line.ops.length == 1,
            'InsertObjectOp was not in its own paragraph.');

        final key = first.type;
        final decoder = embedDecoders[key];
        if (decoder == null) {
          throw ArgumentError.value(
              input, 'input', 'Attribute with missing codec: ${first.type}.');
        }

        final value = decoder(first.value.asMap());
        final embed = BoustroParagraphEmbed(
          first.type,
          value,
        );
        paragraphs.add(embed);
      } else {
        final paragraph = _opsToLine(line);
        paragraphs.add(paragraph);
      }
    }

    return BoustroDocument(paragraphs.build());
  }

  Iterable<_DeltaLine> _groupByLines(List<Op> ops) sync* {
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op is InsertOp) {
        final lineOps = <InsertOp>[];
        var j = 0;
        while (i + j < ops.length && ops[i + j] is InsertOp) {
          final op = ops[i + j] as InsertOp;
          if (!op.text.contains('\n')) {
            lineOps.add(op);
          } else {
            var text = op.text;
            int newline;
            while ((newline = text.indexOf('\n')) > -1) {
              final opText = text.substring(0, newline);

              BuiltMap<String, Object>? lineAttribs;

              // If the op contained only a newline character, the attributes apply
              // to the entire line.
              if (opText.isEmpty) {
                lineAttribs = op.attributes;
              } else {
                final lineEnd = op.copyWith(text: opText);
                lineOps.add(lineEnd);
              }

              yield _DeltaLine(lineOps, lineAttribs);
              lineOps.clear();
              text = text.substring(newline + 1);
            }
            if (text.isNotEmpty) {
              lineOps.add(op.copyWith(text: text));
            }
          }
          j++;
        }
        if (lineOps.isNotEmpty) {
          yield _DeltaLine(lineOps, BuiltMap<String, Object>());
        }
        i += j - 1;
      } else if (op is InsertObjectOp) {
        yield _DeltaLine([op], op.attributes);
      } else {
        throw const FormatException('Only insert operations are supported.');
      }
    }
  }

  BoustroLine _opsToLine(_DeltaLine line) {
    final buffer = StringBuffer();
    final segments = <AttributeSegment>[];

    final attrInsertBehaviorMap = <Type, FullInsertBehavior>{};

    for (final op in line.ops) {
      assert(op is InsertOp, 'Expected InsertOp, but got ${op.runtimeType}.');
      final insert = op as InsertOp;

      final attrs = insert.attributes.entries.map((attrDyn) {
        final codec = attributeCodecs[attrDyn.key];
        if (codec == null) {
          throw ArgumentError.value(attrDyn, 'input',
              'Attribute with missing codec: ${attrDyn.key}.');
        }
        final attr = codec.decoder.convert(attrDyn.value);
        attrInsertBehaviorMap[attr.runtimeType] = codec.insertBehavior;
        return attr;
      });

      final segment =
          AttributeSegment(insert.text.characters, attrs.toBuiltSet());
      segments.add(segment);
      buffer.write(insert.text);
    }

    final spans = SpanList.fromSegments(
      segments,
      (attr) {
        // We went through all attributes, so can't be null.
        return attrInsertBehaviorMap[attr.runtimeType]!;
      },
    );

    final text =
        segments.fold<String>('', (str, segment) => str + segment.text.string);
    return BoustroLine(text, spans, properties: line.properties);
  }
}

// Op-json codec

const _insertKey = 'insert';
const _deleteKey = 'delete';
const _retainKey = 'retain';
const _attributesKey = 'attributes';

/// Convert between an [Op] and a json object.
class OpJsonCodec extends Codec<Op, Map<String, dynamic>> {
  /// Prefer using this constructor as constant. This codec is stateless
  /// so you can use a singleton.
  const OpJsonCodec();

  @override
  Converter<Map<String, dynamic>, Op> get decoder => const _OpJsonDecoder();

  @override
  Converter<Op, Map<String, dynamic>> get encoder => const _OpJsonEncoder();
}

class _OpJsonEncoder extends Converter<Op, Map<String, dynamic>> {
  const _OpJsonEncoder();

  @override
  Map<String, dynamic> convert(Op input) {
    return input.deconstruct(
      insert: (text, attr) => <String, dynamic>{
        _insertKey: text,
        if (attr.isNotEmpty) _attributesKey: attr,
      },
      insertObject: (type, value, attr) => <String, dynamic>{
        _insertKey: {type: value},
        if (attr.isNotEmpty) _attributesKey: attr,
      },
      delete: (len) => <String, dynamic>{_deleteKey: len},
      retain: (len, attr) => <String, dynamic>{
        _retainKey: len,
        if (attr.isNotEmpty) _attributesKey: attr,
      },
    );
  }
}

class _OpJsonDecoder extends Converter<Map<String, dynamic>, Op> {
  const _OpJsonDecoder();

  @override
  Op convert(Map<String, dynamic> input) {
    if (input.keys.isEmpty) {
      throw const FormatException('Op must have a single property.');
    }

    final dynamic attr = input[_attributesKey] ?? <String, dynamic>{};
    if (attr is! Map<String, dynamic>) {
      throw const FormatException();
    }

    if (input.containsKey(_insertKey)) {
      if (input.keys.length > (input[_attributesKey] == null ? 1 : 2)) {
        throw const FormatException(
            'Insert op may only have insert and attributes properties.');
      }

      final value = input[_insertKey] as Object;
      if (value is String) {
        return Op.insert(value, attributes: attr);
      } else if (value is Map<String, dynamic> && value.keys.isNotEmpty) {
        if (value.keys.isEmpty) {
          throw const FormatException(
              'Insert object must have a single property.');
        }
        if (value.keys.length > 1) {
          throw const FormatException(
              'Insert object must have a single property.');
        }

        final type = value.keys.first;
        final object = value[type] as Map<String, dynamic>;
        return Op.insertObject(type, object, attributes: attr);
      } else {
        throw FormatException('Invalid insert operation: $value', input);
      }
    } else if (input.containsKey(_deleteKey)) {
      if (input.keys.length > 1) {
        throw const FormatException('Delete op may only have a delete.');
      }
      final dynamic length = input[_deleteKey];
      if (length is! int) {
        throw const FormatException('Delete op value should be an integer.');
      }
      return DeleteOp(length);
    } else if (input.containsKey(_retainKey)) {
      if (input.keys.length > (input[_attributesKey] == null ? 1 : 2)) {
        throw const FormatException(
            'Retain op may only have retain and attributes properties.');
      }
      final dynamic length = input[_retainKey];
      if (length is! int) {
        throw const FormatException('Retain op value should be an integer.');
      }
      return Op.retain(length, attributes: attr);
    }

    throw FormatException(
        '''Invalid operation key. Must be on of $_insertKey, $_deleteKey or $_retainKey.''',
        input);
  }
}

// Data object that holds a list of [Op] and a property map.
@immutable
class _DeltaLine {
  _DeltaLine(this.ops, [BuiltMap<String, Object>? properties])
      : properties = properties ?? BuiltMap<String, Object>();

  final List<Op> ops;
  final BuiltMap<String, Object> properties;
}
