class JsonUtils {
  /// Extracts a List from a dynamic JSON value.
  /// If the value is a List, it is returned directly.
  /// If it is a Map, it searches for common keys that might contain the list.
  /// Returns an empty list instead of throwing.
  static List<dynamic> extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;

    if (data is Map) {
      // Search common array keys based on standard backend wrappers
      if (data['categories'] is List) return data['categories'];
      if (data['dropdownList'] is List) return data['dropdownList'];
      if (data['items'] is List) return data['items'];
      if (data['data'] is List) return data['data'];

      // If it's a Map but doesn't contain standard keys, we just return empty
      // to avoid breaking the UI.
    }

    return [];
  }

  /// Extracts a Map from a dynamic JSON value.
  /// If the value is a Map, it unwraps common nested object keys.
  static Map<String, dynamic> extractMap(dynamic data) {
    if (data == null) return {};

    if (data is Map) {
      // Unwrap if it's nested
      if (data['category'] is Map)
        return Map<String, dynamic>.from(data['category']);
      if (data['updatedCategory'] is Map)
        return Map<String, dynamic>.from(data['updatedCategory']);
      if (data['outlet'] is Map)
        return Map<String, dynamic>.from(data['outlet']);
      if (data['taxSettings'] is Map)
        return Map<String, dynamic>.from(data['taxSettings']);
      if (data['data'] is Map) return Map<String, dynamic>.from(data['data']);

      // Fallback: it might just be the object itself
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}
