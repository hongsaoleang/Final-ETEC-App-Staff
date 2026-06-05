import 'dart:convert';

dynamic decodeApiResponse(dynamic data) {
  if (data is! String) return data;

  final trimmed = data.trim();
  if (trimmed.isEmpty) return data;

  final jsonStart = _firstJsonIndex(trimmed);
  if (jsonStart == -1) return data;

  final jsonText = trimmed.substring(jsonStart);
  return jsonDecode(jsonText);
}

int _firstJsonIndex(String value) {
  final objectIndex = value.indexOf('{');
  final listIndex = value.indexOf('[');

  if (objectIndex == -1) return listIndex;
  if (listIndex == -1) return objectIndex;
  return objectIndex < listIndex ? objectIndex : listIndex;
}
