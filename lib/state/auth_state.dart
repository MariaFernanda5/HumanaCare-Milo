import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

/// Sessão do usuário: login, cadastro, token e logout.
///
/// Guarda só o token e o nome. O PAPEL não mora aqui — ele pertence ao
/// vínculo com cada paciente (ver VinculoState). Ver CLAUDE.md, seção 7.1.
class AuthState extends ChangeNotifier {
  static const _chaveToken = 'milo_token';
  static const _chaveNome = 'milo_nome';

  String? _token;
  String? _nome;
  bool _carregando = false;
  String? _erro;

  bool get autenticado => _token != null;
  String? get nome => _nome;
  String get primeiroNome => (_nome ?? '').split(' ').first;
  bool get carregando => _carregando;
  String? get erro => _erro;

  /// Chame no arranque do app, antes de decidir a rota inicial.
  Future<void> restaurarSessao() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_chaveToken);
    _nome = p.getString(_chaveNome);
    Api.token = _token;
    notifyListeners();
  }

  Future<bool> login(String email, String senha) async {
    return _tentar(() async {
      final r = await Api.post('/users/login', {'email': email, 'senha': senha});
      await _guardar(r['token'] as String, r['nome'] as String? ?? email);
    });
  }

  Future<bool> criarConta(String nome, String email, String senha) async {
    return _tentar(() async {
      await Api.post('/users/register',
          {'nome': nome, 'email': email, 'senha': senha});
      // Entra direto após cadastrar, para não pedir a senha duas vezes.
      final r = await Api.post('/users/login', {'email': email, 'senha': senha});
      await _guardar(r['token'] as String, nome);
    });
  }

  Future<void> sair() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_chaveToken);
    await p.remove(_chaveNome);
    _token = null;
    _nome = null;
    Api.token = null;
    notifyListeners();
  }

  /// Chamado quando a API devolve 401 em qualquer tela.
  Future<void> sessaoExpirou() async {
    await sair();
    _erro = 'Sua sessão expirou. Entre novamente.';
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ interno

  Future<void> _guardar(String token, String nome) async {
    _token = token;
    _nome = nome;
    Api.token = token;
    final p = await SharedPreferences.getInstance();
    await p.setString(_chaveToken, token);
    await p.setString(_chaveNome, nome);
  }

  Future<bool> _tentar(Future<void> Function() acao) async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      await acao();
      return true;
    } on ApiError catch (e) {
      _erro = e.mensagem;
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
