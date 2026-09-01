import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  // Auth mock
  bool _logado = false;
  String _perfil = '';
  bool get logado => _logado;
  String get perfil => _perfil;

  // Dados do paciente
  final Paciente paciente = MockData.paciente;

  // Remédios (mutável para toggles)
  late List<Remedio> _remedios = MockData.remedios();
  List<Remedio> get remedios => _remedios;

  void toggleRemedio(String id) {
    final i = _remedios.indexWhere((r) => r.id == id);
    if (i >= 0) {
      _remedios[i].tomado = !_remedios[i].tomado;
      notifyListeners();
    }
  }

  // ── NOVO: adicionar / remover medicamento ────────────────────────────────
  void addRemedio(Remedio r) {
    _remedios.add(r);
    notifyListeners();
  }

  void removeRemedio(String id) {
    _remedios.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Mensagens por canal
  final Map<String, List<Mensagem>> _msgs = {
    'familia': MockData.mensagensFamilia(),
    'cuidador': MockData.mensagensCuidador(),
    'milo': MockData.mensagensMilo(),
  };

  List<Mensagem> mensagens(String canal) => List.unmodifiable(_msgs[canal] ?? []);

  void addMensagem(String canal, Mensagem msg) {
    _msgs[canal] ??= [];
    _msgs[canal]!.add(msg);
    notifyListeners();
  }

  // SOS
  bool _sosAtivado = false;
  bool get sosAtivado => _sosAtivado;
  void acionarSos() {
    _sosAtivado = true;
    notifyListeners();
    // Reseta após 5s para poder usar novamente na demo
    Future.delayed(const Duration(seconds: 5), () {
      _sosAtivado = false;
      notifyListeners();
    });
  }

  // Login mock
  void login(String p) {
    _logado = true;
    _perfil = p;
    notifyListeners();
  }

  void logout() {
    _logado = false;
    _perfil = '';
    notifyListeners();
  }
}
