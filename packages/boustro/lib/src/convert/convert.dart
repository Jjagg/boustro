import 'dart:convert';

/// Create a [Converter] with a closure instead of a class.
class ClosureConverter<S, T> extends Converter<S, T> {
  /// Create a converter with a conversion closure.
  const ClosureConverter(this._convert);

  final T Function(S) _convert;

  @override
  T convert(S input) => _convert(input);
}
