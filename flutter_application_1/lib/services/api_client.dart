import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centraliza URL base, autenticación, solicitudes y errores HTTP de la app.
class ApiClient {
  static final String baseUrl = _defaultBaseUrl;

  static String? accessToken;

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Construye una URI de la API y conserva los parámetros de consulta.
  static Uri uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query);
  }

  /// Resuelve imágenes relativas contra la API y conserva URLs absolutas.
  static String assetUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final value = path.trim();
    if (Uri.tryParse(value)?.hasScheme ?? false) return value;
    final relativePath = value.startsWith('/') ? value.substring(1) : value;
    return Uri.parse('$baseUrl/').resolve(relativePath).toString();
  }

  /// Ejecuta una solicitud GET y devuelve la respuesta decodificada.
  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    try {
      final response = await http
          .get(
            uri(path, query),
            headers: _headers(authenticated: authenticated),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage(path));
    }
  }

  /// Envía un cuerpo JSON con el método HTTP indicado.
  static Future<dynamic> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final headers = _headers(authenticated: authenticated)
      ..['Content-Type'] = 'application/json';
    final request = http.Request(method, uri(path, query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage(path));
    }
  }

  /// Envía campos y bytes de imagen como una solicitud multipart.
  static Future<dynamic> upload(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filename,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest('POST', uri(path))
      ..headers.addAll(_headers())
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
      );
    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 30));
      return _decode(response);
    } on TimeoutException {
      throw Exception(_timeoutMessage(path));
    }
  }

  static String _timeoutMessage(String path) =>
      'Tiempo de espera agotado al conectar con $baseUrl$path. '
      'Verifica que la API esté activa y que el dispositivo pueda acceder al servidor.';

  static Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// Decodifica JSON o texto y convierte respuestas HTTP fallidas en errores.
  static dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = response.body;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;
      throw Exception(
        detail?.toString() ??
            'Error HTTP ${response.statusCode}: ${response.body}',
      );
    }
    return data;
  }
}
