class ApiPayload {
  static dynamic unwrap(
    Map<String, dynamic> response, {
    List<String> preferredKeys = const [],
  }) {
    for (final key in preferredKeys) {
      if (response.containsKey(key) && response[key] != null) {
        return response[key];
      }
    }

    if (response.containsKey('data')) {
      return response['data'];
    }

    return response;
  }

  static Map<String, dynamic> unwrapObject(
    Map<String, dynamic> response, {
    List<String> preferredKeys = const [],
  }) {
    final payload = unwrap(response, preferredKeys: preferredKeys);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return response;
  }

  static List<dynamic> unwrapList(
    Map<String, dynamic> response, {
    List<String> preferredKeys = const [],
  }) {
    final payload = unwrap(response, preferredKeys: preferredKeys);
    if (payload is List) {
      return payload;
    }
    return const [];
  }
}
