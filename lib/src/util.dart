T decodeEnum<T>(List<T> values, int? index, {required T defaultValue}) =>
    index != null && index < values.length ? values[index] : defaultValue;

T decodeMapEnum<T>(Map<int, T> values, int? index, {required T defaultValue}) =>
    values[index] ?? defaultValue;

T? firstWhereOrNull<T>(Iterable<T> iterable, bool Function(T element) test) {
  for (var element in iterable) {
    if (test(element)) return element;
  }
  return null;
}
