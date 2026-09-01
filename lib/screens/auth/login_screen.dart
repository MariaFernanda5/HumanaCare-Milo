import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../models/app_state.dart';
import '../../widgets/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _erro;

  Future<void> _entrar() async {
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Email ou senha inválidos');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      await FirebaseService.loginWithEmailAndPassword(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      context.read<AppState>().login('paciente');
      context.go('/paciente');
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const AuthHeader(),
              const SizedBox(height: 48),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Login',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Email',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 6),
              HCField(
                hint: 'seuemail@exemplo.com',
                controller: _emailCtrl,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Senha',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              ),
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
                const SizedBox(height: 10),
                Text(_erro!, style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 13)),
              ],

              const SizedBox(height: 28),
              HCButton(label: 'Entrar', onTap: _entrar, loading: _loading),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () {},
                child: Text('Esqueci a senha',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
              ),

              const Divider(height: 32, color: AppTheme.divider),

              HCOutlineButton(label: 'Cria conta', onTap: () => GoRouter.of(context).go('/register')),
              const SizedBox(height: 16),

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
}
