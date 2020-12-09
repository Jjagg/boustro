import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Quill delta operation.
@immutable
abstract class Op extends Equatable {
  const Op._();

  /// Create an insert operation.
  factory Op.insert(
    String text, {
    Map<String, dynamic>? attributes,
  }) = InsertOp;

  /// Create an insert operation that inserts an object.
  factory Op.insertObject(
    String type,
    Map<String, dynamic>? value, {
    Map<String, dynamic>? attributes,
  }) = InsertObjectOp;

  /// Create a retain operation.
  factory Op.retain(
    int length, {
    Map<String, dynamic>? attributes,
  }) = RetainOp;

  /// Create a delete operation.
  const factory Op.delete(int length) = DeleteOp;

  /// Execute a function depending on the type of this operation.
  S deconstruct<S>({
    required S Function(String, BuiltMap<String, dynamic>) insert,
    required S Function(String, Object, BuiltMap<String, dynamic>) insertObject,
    required S Function(int, BuiltMap<String, dynamic>) retain,
    required S Function(int) delete,
  });
}

/// A Quill delta operation that inserts formatted text.
@immutable
class InsertOp extends Op {
  /// Create an insert operation.
  InsertOp(this.text, {Map<String, dynamic>? attributes})
      : attributes = attributes == null
            ? BuiltMap<String, Object>()
            : BuiltMap<String, Object>.from(attributes),
        super._();

  /// The plain text value.
  final String text;

  /// Attributes applied to the text that determine formatting.
  final BuiltMap<String, Object> attributes;

  /// Create a copy of this operation with the given fields replaced with the
  /// new values.
  InsertOp copyWith({String? text, Map<String, Object>? attributes}) =>
      InsertOp(text ?? this.text,
          attributes: attributes ?? this.attributes.asMap());

  @override
  S deconstruct<S>({
    required S Function(String, BuiltMap<String, Object>) insert,
    required S Function(String, Object, BuiltMap<String, Object>) insertObject,
    required S Function(int, BuiltMap<String, Object>) retain,
    required S Function(int) delete,
  }) =>
      insert(text, attributes);

  @override
  String toString() {
    return '[insert] $text ${attributes.isNotEmpty ? '(${attributes.keys.join(',')})' : ''}';
  }

  @override
  List<Object?> get props => [text, attributes];
}

/// A Quill delta operation that inserts an object.
///
/// For the purposes of other operations, the length of an insert object
/// operation is always considered to be one.
@immutable
class InsertObjectOp extends Op {
  /// Create an insert operation that inserts an object.
  InsertObjectOp(this.type, Map<String, dynamic>? value,
      {Map<String, dynamic>? attributes})
      : value = BuiltMap<String, Object>.from(value ?? <String, dynamic>{}),
        attributes =
            BuiltMap<String, Object>.from(attributes ?? <String, dynamic>{}),
        super._();

  /// The type of the object. This value is used to determine how the object
  /// is parsed and displayed.
  final String type;

  /// Value of the object in JSON format.
  final BuiltMap<String, Object> value;

  /// Additional attributes that might affect how this object is displayed.
  final BuiltMap<String, Object> attributes;

  /// Create a copy of this operation with the given fields replaced with the
  /// new values.
  InsertObjectOp copyWith({
    String? type,
    Map<String, Object>? value,
    Map<String, Object>? attributes,
  }) =>
      InsertObjectOp(
        type ?? this.type,
        value ?? this.value.asMap(),
        attributes: attributes ?? this.attributes.asMap(),
      );

  @override
  S deconstruct<S>({
    required S Function(String, BuiltMap<String, dynamic>) insert,
    required S Function(String, Object, BuiltMap<String, dynamic>) insertObject,
    required S Function(int, BuiltMap<String, dynamic>) retain,
    required S Function(int) delete,
  }) =>
      insertObject(type, value, attributes);

  @override
  String toString() {
    return '[insertObj] $type: $value ${attributes.isNotEmpty ? '(${attributes.keys.join(',')})' : ''}';
  }

  @override
  List<Object?> get props => [type, value, attributes];
}

/// A Quill delta retain operation. Can apply formatting over its [length].
@immutable
class RetainOp extends Op {
  /// Create a retain operation.
  RetainOp(this.length, {Map<String, dynamic>? attributes})
      : attributes = attributes == null
            ? BuiltMap<String, Object>()
            : BuiltMap<String, Object>.from(attributes),
        super._();

  /// How many UTF8 characters this operation applies to.
  // FIXME we need to transform indices and lengths so the serialized
  //       versions apply to the UTF8 text.
  final int length;

  /// The attributes to apply over [length].
  final BuiltMap<String, dynamic> attributes;

  /// Create a copy of this operation with the given fields replaced with the
  /// new values.
  RetainOp copyWith({int? length, Map<String, dynamic>? attributes}) =>
      RetainOp(
        length ?? this.length,
        attributes: attributes ?? this.attributes.asMap(),
      );

  @override
  S deconstruct<S>({
    required S Function(String, BuiltMap<String, dynamic>) insert,
    required S Function(String, Object, BuiltMap<String, dynamic>) insertObject,
    required S Function(int, BuiltMap<String, dynamic>) retain,
    required S Function(int) delete,
  }) =>
      retain(length, attributes);

  @override
  String toString() {
    return '[retain] $length ${attributes.isNotEmpty ? '(${attributes.keys.join(',')})' : ''}';
  }

  @override
  List<Object?> get props => [length, attributes];
}

/// A Quill delta delete operation.
@immutable
class DeleteOp extends Op {
  /// Create a delete operation.
  const DeleteOp(this.length) : super._();

  /// Number of characters to delete.
  final int length;

  @override
  S deconstruct<S>({
    required S Function(String, BuiltMap<String, dynamic>) insert,
    required S Function(String, Object, BuiltMap<String, dynamic>) insertObject,
    required S Function(int, BuiltMap<String, dynamic>) retain,
    required S Function(int) delete,
  }) =>
      delete(length);

  @override
  String toString() {
    return '[delete] $length';
  }

  @override
  List<Object?> get props => [length];
}
