import 'package:go_router/go_router.dart';
import '../screens/paciente/paciente_home.dart';
import '../screens/paciente/tabs/sos_screen.dart';

import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/perfil_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRouter {
  // Single router instance to avoid recreating on rebuilds
  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (_, __) => const PerfilScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/paciente',
        builder: (_, __) => const PacienteHome(),
      ),
      GoRoute(
        path: '/sos',
        builder: (_, __) => const SosScreen(),
      ),
    ],
    redirect: (context, state) {
      final appState = Provider.of<AppState>(context, listen: false);

      final loggedIn = appState.logado;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/paciente';


      return null;
    },
  );

  static GoRouter router() => _router;
}

