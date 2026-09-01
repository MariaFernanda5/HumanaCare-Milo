# Arquivos base — onde colocar e como ligar

Três arquivos para colar dentro do `HumanaCare-main`. Eles são a fundação da Etapa 1.

```
HumanaCare-main/lib/
├── core/
│   └── api.dart              ← novo
└── state/
    ├── auth_state.dart       ← novo
    └── vinculo_state.dart    ← novo
```

---

## 1. Instalar a dependência que falta

```bash
flutter pub add shared_preferences
```

As outras (`http`, `provider`, `go_router`, `intl`) já estão no seu `pubspec.yaml`.

---

## 2. Registrar os estados no `main.dart`

O seu `main.dart` já usa `provider` para o `AppState`. Acrescente os dois novos:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_state.dart';
import 'state/vinculo_state.dart';
import 'models/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthState();
  await auth.restaurarSessao();   // recupera o token salvo

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => VinculoState()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MiloApp(),
    ),
  );
}
```

---

## 3. Rodar apontando para a API

```bash
# desenvolvimento
flutter run -d chrome --dart-define=API_URL=http://localhost:3000

# depois do deploy
flutter build apk --release --dart-define=API_URL=https://milo-api.azurewebsites.net
```

A URL **não fica chumbada no código** — é isso que permite trocar de ambiente sem editar arquivo.

> No Android, `localhost` aponta para o próprio aparelho. Para testar no emulador use `http://10.0.2.2:3000`; em celular físico use o IP da sua máquina na rede, por exemplo `http://192.168.0.15:3000`.

---

## 4. Ligar a tela de login

Na sua `login_screen.dart`, troque o que hoje chama `AppState.login()` por:

```dart
final auth = context.read<AuthState>();
final ok = await auth.login(emailCtrl.text.trim(), senhaCtrl.text);

if (!mounted) return;
if (ok) {
  await context.read<VinculoState>().carregar();
  if (!mounted) return;
  final v = context.read<VinculoState>();
  // Sem paciente ainda → onboarding. Com paciente → home.
  context.go(v.vazio ? '/comecar' : '/inicio');
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(auth.erro ?? 'Não foi possível entrar')),
  );
}
```

Para o botão mostrar o estado de carregando:

```dart
final carregando = context.watch<AuthState>().carregando;

ElevatedButton(
  onPressed: carregando ? null : _entrar,
  child: carregando
      ? const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : const Text('Entrar'),
)
```

---

## 5. Usar o papel nas telas

**Nunca** guarde "familiar" ou "cuidador" no usuário. Leia sempre do vínculo:

```dart
final v = context.watch<VinculoState>();

// mostrar o selo
if (v.ativo != null) Text(v.ativo!.selo);

// escolher a navegação
final abas = navegacaoPara(v.navegacao);   // 'paciente' | 'cuidador' | 'familiar'

// esconder botão que daria 403
if (v.podeGerenciarEquipe)
  ElevatedButton(onPressed: _convidar, child: const Text('Convidar cuidador')),

// ação de registro
if (v.podeRegistrar)
  BotaoConfirmarDose(doseId: d.id),
```

O servidor continua sendo a autoridade — isso aqui só evita mostrar botão que vai falhar.

---

## 6. Tratar sessão expirada

Em qualquer tela que chame a API:

```dart
try {
  await Api.post('/pacientes/${v.pacienteId}/doses/$doseId/confirmar');
} on ApiError catch (e) {
  if (e.naoAutenticado) {
    await context.read<AuthState>().sessaoExpirou();
    if (mounted) context.go('/login');
    return;
  }
  if (mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.mensagem)));
  }
}
```

O `ApiError.mensagem` **já vem em português e pronto para a tela**. Nunca mostre `e.toString()`.

---

## 7. Testar antes de seguir

```bash
flutter analyze     # não pode ter erro
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

Roteiro de teste:

1. Criar conta → deve entrar direto
2. Fechar e reabrir o app → deve continuar logado (a sessão foi restaurada)
3. Cadastrar paciente → o selo deve dizer "Você é administradora do perfil de X"
4. Sair e entrar de novo → o paciente deve continuar lá

Se os quatro funcionarem, a Etapa 1 está pronta. Commite:

```bash
git add . && git commit -m "etapa 1: api, autenticacao e vinculo"
```

---

## Depois disso

No Claude Code:

```
A Etapa 1 do CLAUDE.md está pronta: api.dart, auth_state.dart e
vinculo_state.dart funcionando, login ligado à API.

Agora execute a Etapa 2: substituir MockData pelas chamadas reais em
remédios e doses. Mantenha o visual das telas como está. Comece só pela
tela de remédios do paciente.
```

Uma tela por vez, testando e commitando entre elas.
