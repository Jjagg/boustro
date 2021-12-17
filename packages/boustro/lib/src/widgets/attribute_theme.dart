import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../spans/attribute_span.dart';

/// Theming for [TextAttribute].
class AttributeTheme extends InheritedTheme {
  /// Create an attribute theme.
  const AttributeTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  /// The properties that can affect how [TextAttribute]s are displayed.
  final AttributeThemeData data;

  /// Returns the [data] from the closest [AttributeTheme] ancestor. If there is
  /// no ancestor, it returns [AttributeThemeData.empty]
  static AttributeThemeData of(BuildContext context) {
    final attributeTheme =
        context.dependOnInheritedWidgetOfExactType<AttributeTheme>();
    return attributeTheme?.data ?? AttributeThemeData.empty;
  }

  @override
  bool updateShouldNotify(covariant AttributeTheme oldWidget) {
    return data != oldWidget.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AttributeTheme(data: data, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AttributeThemeData>('data', data));
  }
}

/// Map of properties that can be used to theme [TextAttribute].
/// Data class for [AttributeTheme].
class AttributeThemeData extends Equatable {
  /// Create attribute theming data with a map of properties.
  const AttributeThemeData(this.properties);

  /// Attribute theme data without any properties set.
  static final AttributeThemeData empty =
      AttributeThemeData(BuiltMap<String, Object>());

  /// Properties that can be used to customize [TextAttribute]s.
  final BuiltMap<String, Object> properties;

  /// Get the value of a property in this theme.
  T? get<T>(String key) {
    return properties[key] as T?;
  }

  @override
  List<Object?> get props => [properties];
}

/// Builder for [AttributeThemeData].
class AttributeThemeBuilder {
  /// Create an attribute theme builder. Can have starting properties.
  AttributeThemeBuilder([Map<String, Object>? properties])
      : _properties = properties ?? {};

  final Map<String, Object> _properties;

  /// Returns the value for the given [key] or null if [key] is not in the map.
  Object? operator [](String key) => _properties[key];

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key/value pair is added to the map.
  void operator []=(String key, Object? value) {
    if (value == null) {
      _properties.remove(key);
    } else {
      _properties[key] = value;
    }
  }

  /// Remove a property.
  void remove(String key) {
    _properties.remove(key);
  }

  /// Build the properties set on this builder into an immutable attribute theme
  /// data object.
  AttributeThemeData build() {
    return AttributeThemeData(_properties.build());
  }
}
