/// Utilitas untuk mapping JSON -> model domain sederhana.
abstract class JsonMapper<T> {
  const JsonMapper();

  T fromJson(Map<String, dynamic> json);
}

/// Contoh mapper generic (bisa diperluas untuk modul lain).
class MapListMapper<T> {
  MapListMapper(this.mapper);

  final JsonMapper<T> mapper;

  List<T> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(mapper.fromJson)
        .toList();
  }
}
