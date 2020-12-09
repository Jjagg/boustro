class Result<T, E> {
  Result._({this.value, this.err});
  factory Result.ok(T value) => Result._(value: value);
  factory Result.err(E err) => Result._(err: err);

  final T? value;
  final E? err;

  S deconstruct<S>({required S Function(T) value, required S Function(E) err}) {
    // ignore: null_check_on_nullable_type_parameter
    return this.value == null ? err(this.err!) : value(this.value!);
  }

  S? deconstructOrNull<S>({S Function(T)? value, required S Function(E)? err}) {
    return deconstruct(
      value: (v) => value?.call(v),
      err: (e) => err?.call(e),
    );
  }

  Result<S, E> map<S>(S Function(T) f) => deconstruct(
        value: (v) => Result.ok(f(v)),
        err: (e) => Result.err(e),
      );
}
