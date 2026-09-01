import 'dart:convert';
import 'package:http/http.dart' as http;

/// Erro de API já traduzido para linguagem de usuário.
/// Nunca mostre a exceção crua na tela — use [mensagem].
class ApiError implements Exception {
  final int status;
  final String mensagem;
  ApiError(this.status, this.mensagem);

  bool get naoAutenticado => status == 401;
  bool get semPermissao => status == 403;

  @override
  String toString() => 'ApiError($status): $mensagem';
}

/// Cliente HTTP do Milo.
///
/// A URL base vem de --dart-define, para não ficar chumbada no código:
///   flutter run --dart-define=API_URL=http://localhost:3000
///   flutter build apk --dart-define=API_URL=https://milo-api.azurewebsites.net
class Api {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration _timeout = Duration(seconds: 15);

  /// Token JWT da sessão. Preenchido pelo AuthState no login.
  static String? token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ------------------------------------------------------------ verbos

  static Future<dynamic> get(String caminho) =>
      _executar(() => http.get(_uri(caminho), headers: _headers));

  static Future<dynamic> post(String caminho, [Map<String, dynamic>? corpo]) =>
      _executar(() => http.post(_uri(caminho),
          headers: _headers, body: corpo == null ? null : jsonEncode(corpo)));

  static Future<dynamic> patch(String caminho, [Map<String, dynamic>? corpo]) =>
      _executar(() => http.patch(_uri(caminho),
          headers: _headers, body: corpo == null ? null : jsonEncode(corpo)));

  static Future<dynamic> delete(String caminho) =>
      _executar(() => http.delete(_uri(caminho), headers: _headers));

  static Uri _uri(String caminho) => Uri.parse('$baseUrl$caminho');

  // ------------------------------------------------------------ execução

  static Future<dynamic> _executar(Future<http.Response> Function() req) async {
    late http.Response r;

    try {
      r = await req().timeout(_timeout);
    } catch (_) {
      // Sem internet, DNS, timeout — tudo cai aqui.
      throw ApiError(0, 'Não conseguimos conectar. Verifique sua internet.');
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }

    throw ApiError(r.statusCode, _mensagem(r));
  }

  /// Traduz o código HTTP para uma frase que pode ir direto na tela.
  /// O backend responde 404 (e não 403) quando o usuário não tem vínculo
  /// com o paciente, para não revelar a existência de pacientes de terceiros.
  static String _mensagem(http.Response r) {
    switch (r.statusCode) {
      case 400:
        return _erroDoCorpo(r) ?? 'Confira os dados e tente de novo.';
      case 401:
        return 'Sua sessão expirou. Entre novamente.';
      case 403:
        return 'Seu perfil não permite esta ação.';
      case 404:
        return 'Não encontramos o que você procura.';
      case 409:
        return _erroDoCorpo(r) ?? 'Isso já foi registrado.';
      default:
        return 'Algo deu errado do nosso lado. Tente de novo em instantes.';
    }
  }

  static String? _erroDoCorpo(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      final m = j is Map ? (j['erro'] ?? j['error']) : null;
      return m is String && m.isNotEmpty ? m : null;
    } catch (_) {
      return null;
    }
  }
}
