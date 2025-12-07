import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pbp_django_auth/pbp_django_auth.dart';

extension MultipartRequestExtension on CookieRequest {
  Future<Map<String, dynamic>> postMultipart(
    String url,
    Map<String, String> fields,
    Map<String, http.MultipartFile> files,
  ) async {
    var uri = Uri.parse(url);

    var request = http.MultipartRequest("POST", uri);
    request.fields.addAll(fields);
    request.files.addAll(files.values);

    if (headers["Cookie"] != null) {
      request.headers["Cookie"] = headers["Cookie"]!;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {"message": "Gagal decode response: $e"};
      }
    } else {
      return {
        "message": "Gagal upload data. Status code: ${response.statusCode}",
        "body": response.body
      };
    }
  }
}
