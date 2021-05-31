T decodeEnum<T>(List<T> values, int index, {int defaultIndex = 0}) =>
    values[index >= values.length ? defaultIndex : index];

T decodeMapEnum<T>(Map<int, T> values, int index, {int defaultIndex = 0}) =>
    values[index >= values.length ? defaultIndex : index]!;
