import 'package:flutter/foundation.dart';
import '../core/api.dart';

/// Os quatro papéis possíveis numa relação com um paciente.
enum Papel { administrador, cuidador, visualizador, paciente }

Papel papelDe(String s) => Papel.values.firstWhere(
      (p) => p.name == s,
      orElse: () => Papel.visualizador,
    );

/// A relação entre o usuário logado e UM paciente.
///
/// Espelha a tabela cuidadores_paciente do banco.
class Vinculo {
  final int pacienteId;
  final String pacienteNome;
  final Papel papel;

  const Vinculo({
    required this.pacienteId,
    required this.pacienteNome,
    required this.papel,
  });

  factory Vinculo.fromJson(Map<String, dynamic> j) => Vinculo(
        pacienteId: j['id'] as int,
        pacienteNome: j['nome'] as String,
        papel: papelDe((j['papel'] ?? 'visualizador') as String),
      );

  // ---------------------------------------------------------- permissões
  // Espelham o middleware autorizarPaciente do backend. O servidor continua
  // sendo a autoridade — isto aqui só evita mostrar botão que vai dar 403.

  bool get podeEditarPaciente => papel == Papel.administrador;
  bool get podeGerenciarEquipe => papel == Papel.administrador;

  bool get podeRegistrar =>
      papel == Papel.administrador || papel == Papel.cuidador;

  bool get podeConfirmarDose =>
      papel == Papel.administrador ||
      papel == Papel.cuidador ||
      papel == Papel.paciente;

  /// Qual conjunto de abas mostrar. Ver CLAUDE.md, seção 7.1.
  String get navegacao {
    switch (papel) {
      case Papel.cuidador:
        return 'cuidador';
      case Papel.paciente:
        return 'paciente';
      case Papel.administrador:
      case Papel.visualizador:
        return 'familiar';
    }
  }

  /// Texto do selo no topo da tela inicial.
  String get selo {
    switch (papel) {
      case Papel.paciente:
        return 'Este é o seu perfil de saúde';
      case Papel.administrador:
        return 'Você é administradora do perfil de $pacienteNome';
      case Papel.cuidador:
        return 'Você é cuidadora de $pacienteNome';
      case Papel.visualizador:
        return 'Acompanhando $pacienteNome';
    }
  }
}

/// Guarda os pacientes do usuário e qual está ativo.
///
/// REGRA CENTRAL DO PRODUTO: o papel não é do usuário, é da relação dele
/// com cada paciente. A mesma pessoa pode ser administradora do perfil da
/// mãe e visualizadora do perfil do sogro. Toda tela lê o papel daqui.
class VinculoState extends ChangeNotifier {
  List<Vinculo> _vinculos = [];
  Vinculo? _ativo;
  bool _carregando = false;
  String? _erro;

  List<Vinculo> get vinculos => List.unmodifiable(_vinculos);
  Vinculo? get ativo => _ativo;
  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get vazio => !_carregando && _vinculos.isEmpty;

  /// Atalhos para as telas não precisarem checar nulo toda hora.
  Papel get papel => _ativo?.papel ?? Papel.visualizador;
  String get navegacao => _ativo?.navegacao ?? 'familiar';
  bool get podeGerenciarEquipe => _ativo?.podeGerenciarEquipe ?? false;
  bool get podeRegistrar => _ativo?.podeRegistrar ?? false;
  int? get pacienteId => _ativo?.pacienteId;

  /// Carrega os pacientes vinculados. Chame logo após o login.
  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final lista = await Api.get('/pacientes') as List;
      _vinculos = lista
          .map((j) => Vinculo.fromJson(j as Map<String, dynamic>))
          .toList();
      // Mantém o ativo se ainda existir; senão pega o primeiro.
      final idAtivo = _ativo?.pacienteId;
      _ativo = _vinculos.isEmpty
          ? null
          : _vinculos.firstWhere(
              (v) => v.pacienteId == idAtivo,
              orElse: () => _vinculos.first,
            );
    } on ApiError catch (e) {
      _erro = e.mensagem;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void selecionar(int pacienteId) {
    final v = _vinculos.where((x) => x.pacienteId == pacienteId);
    if (v.isEmpty) return;
    _ativo = v.first;
    notifyListeners();
  }

  /// Após cadastrar um paciente o usuário vira ADMINISTRADOR dele.
  /// O papel é derivado da ação, nunca declarado. Ver CLAUDE.md, seção 7.2.
  Future<bool> cadastrarPaciente(Map<String, dynamic> dados) async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final r = await Api.post('/pacientes', dados) as Map<String, dynamic>;
      final novo = Vinculo(
        pacienteId: r['id'] as int,
        pacienteNome: r['nome'] as String,
        papel: Papel.administrador,
      );
      _vinculos = [..._vinculos, novo];
      _ativo = novo;
      return true;
    } on ApiError catch (e) {
      _erro = e.mensagem;
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void limpar() {
    _vinculos = [];
    _ativo = null;
    _erro = null;
    notifyListeners();
  }
}
