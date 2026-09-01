import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../widgets/shared.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _erro;

  Future<void> _criar() async {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      await FirebaseService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      context.read<AppState>().login('paciente');
      context.go('/perfil');
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Email ou senha inválidos');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const AuthHeader(),
              const SizedBox(height: 40),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Criar conta',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 20),

              _label('Nome completo'),
              const SizedBox(height: 6),
              HCField(hint: 'João Silva', controller: _nomeCtrl),
              const SizedBox(height: 14),

              _label('Email'),
              const SizedBox(height: 6),
              HCField(hint: 'seuemail@exemplo.com', controller: _emailCtrl, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),

              _label('Senha'),
              const SizedBox(height: 6),
              HCField(
                hint: '••••••••',
                controller: _senhaCtrl,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textLight,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  _erro!,
                  style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 28),
              HCButton(label: 'Criar conta', onTap: _criar, loading: _loading),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Já tenho conta',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Termos de uso',
                  style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  );
}
