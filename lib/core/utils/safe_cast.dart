List<Map<String, dynamic>> safeListCast(dynamic response) {
  if (response == null) return [];
  if (response is! List) return [];
  return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Map<String, dynamic>? safeMapCast(dynamic response) {
  if (response == null) return null;
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.isNotEmpty) {
    return Map<String, dynamic>.from(response.first as Map);
  }
  return null;
}
