import 'package:built_collection/built_collection.dart';
import 'package:equatable/equatable.dart';

/// An empty [BuiltList] with a `const` constructor.
///
/// Workaround for https://github.com/google/built_collection.dart/issues/230.
// ignore: avoid_implementing_value_types
class EmptyBuiltList<E> extends Equatable implements BuiltList<E> {
  /// Create an empty [BuiltList].
  const EmptyBuiltList();

  @override
  List<dynamic> get props => const <dynamic>[];

  BuiltList<E> get _list => BuiltList<E>();

  @override
  BuiltList<E> operator +(BuiltList<E> other) => _list + other;

  @override
  E operator [](int index) => _list[index];

  @override
  bool any(bool Function(E p1) test) => _list.any(test);

  @override
  List<E> asList() => _list.asList();

  @override
  Map<int, E> asMap() => _list.asMap();

  @override
  Iterable<T> cast<T>() => _list.cast<T>();

  @override
  bool contains(Object? element) => _list.contains(element);

  @override
  E elementAt(int index) => _list.elementAt(index);

  @override
  bool every(bool Function(E p1) test) => _list.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E p1) f) => _list.expand(f);

  @override
  E get first => _list.first;

  @override
  E firstWhere(bool Function(E p1) test, {E Function()? orElse}) =>
      _list.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T p1, E p2) combine) =>
      _list.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _list.followedBy(other);

  @override
  void forEach(void Function(E p1) f) => _list.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => _list.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  @override
  int indexWhere(bool Function(E p1) test, [int start = 0]) =>
      _list.indexWhere(test, start);

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  String join([String separator = '']) => _list.join(separator);

  @override
  E get last => _list.last;

  @override
  int lastIndexOf(E element, [int? start]) => _list.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E p1) test, [int? start]) =>
      _list.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E p1) test, {E Function()? orElse}) =>
      _list.lastWhere(test, orElse: orElse);

  @override
  int get length => _list.length;

  @override
  Iterable<T> map<T>(T Function(E p1) f) => _list.map(f);

  @override
  BuiltList<E> rebuild(dynamic Function(ListBuilder<E> p1) updates) =>
      _list.rebuild(updates);

  @override
  E reduce(E Function(E p1, E p2) combine) => _list.reduce(combine);

  @override
  Iterable<E> get reversed => _list.reversed;

  @override
  E get single => _list.single;

  @override
  E singleWhere(bool Function(E p1) test, {E Function()? orElse}) =>
      _list.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int n) => _list.skip(n);

  @override
  Iterable<E> skipWhile(bool Function(E p1) test) => _list.skipWhile(test);

  @override
  BuiltList<E> sublist(int start, [int? end]) => _list.sublist(start, end);

  @override
  Iterable<E> take(int n) => _list.take(n);

  @override
  Iterable<E> takeWhile(bool Function(E p1) test) => _list.takeWhile(test);

  @override
  ListBuilder<E> toBuilder() => _list.toBuilder();

  @override
  BuiltList<E> toBuiltList() => _list.toBuiltList();

  @override
  BuiltSet<E> toBuiltSet() => _list.toBuiltSet();

  @override
  List<E> toList({bool growable = true}) => _list.toList(growable: growable);

  @override
  Set<E> toSet() => _list.toSet();

  @override
  Iterable<E> where(bool Function(E p1) test) => _list.where(test);

  @override
  Iterable<T> whereType<T>() => _list.whereType<T>();
}
