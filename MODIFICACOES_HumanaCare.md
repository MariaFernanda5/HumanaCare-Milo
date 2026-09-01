# HumanaCare-main — todas as modificações necessárias

Lista arquivo por arquivo, do estado atual ao app funcional. Escrita a partir da leitura do código real.

**Legenda:** 🔴 bloqueia o funcionamento · 🟡 necessário para a entrega · 🟢 melhoria

---

## Parte 0 — Limpeza (faça primeiro, 20 min)

### 0.1 🔴 Remover `.dart_tool copy` do versionamento

São **mais de 300 arquivos** commitados, incluindo dados de perfil do Chrome: `Login Data`, `Cookies`, `History`. É a primeira coisa que o professor vê ao abrir o repositório.

```bash
git rm -r --cached ".dart_tool copy"
rm -rf ".dart_tool copy"
```

### 0.2 🔴 Corrigir o `.gitignore`

```
.dart_tool/
.dart_tool copy/
build/
.env
*.log
```

### 0.3 🟡 Renomear o projeto

O `AndroidManifest` e o `MainActivity.kt` usam `com.example.humanacare_paciente`. Para gerar APK, troque para algo próprio, como `br.com.humanacare.milo`.

```bash
git add . && git commit -m "limpeza: remove artefatos de build do versionamento"
```

---

## Parte 1 — Arquivos novos

| Arquivo | O que faz | Estado |
|---|---|---|
| `lib/core/api.dart` | Cliente HTTP, token, tradução de erro | ✅ já escrito |
| `lib/state/auth_state.dart` | Login, cadastro, sessão | ✅ já escrito |
| `lib/state/vinculo_state.dart` | Paciente ativo e papel — o RBAC | ✅ já escrito |
| `lib/state/cuidado_state.dart` | Doses, tarefas, histórico via API | a escrever |
| `lib/screens/onboarding/comecar_screen.dart` | "Como você quer começar?" | a escrever |
| `lib/screens/onboarding/vincular_screen.dart` | Entrar por código | a escrever |
| `lib/screens/comum/equipe_screen.dart` | Equipe, convite, revogação | a escrever |
| `lib/screens/comum/historico_screen.dart` | Linha do tempo | a escrever |
| `lib/screens/cuidador/cuidador_home.dart` | Agenda do turno | a escrever |
| `lib/screens/familiar/familiar_home.dart` | Estado do dia em uma frase | a escrever |
| `lib/widgets/selo_vinculo.dart` | "Você é administradora do perfil de X" | a escrever |
| `lib/widgets/nav_por_papel.dart` | Navegação que muda conforme o papel | a escrever |

Dependência a instalar:

```bash
flutter pub add shared_preferences
```

---

## Parte 2 — Arquivos a modificar

### 2.1 🔴 `lib/main.dart`

**Hoje:** registra só o `AppState`.

**Precisa:** registrar os três estados e restaurar a sessão antes de subir o app, senão o usuário é jogado para o login a cada abertura.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final auth = AuthState();
  await auth.restaurarSessao();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => VinculoState()),
        ChangeNotifierProvider(create: (_) => CuidadoState()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const HumanaCareApp(),
    ),
  );
}
```

Troque também o `title: 'HumanaCare'` por `'Milo'` — o app é Milo, a startup é HumanaCare.

---

### 2.2 🔴 `lib/router/app_router.dart`

Tem **três problemas**.

**Problema 1 — o redirect não reage.** O `GoRouter` é `static final`, criado uma vez, e o `redirect` lê o provider com `listen: false`. Quando o login acontece, nada dispara o redirecionamento. Falta `refreshListenable`.

**Problema 2 — o redirect usa `AppState.logado`**, que é o login falso. Precisa usar `AuthState.autenticado`.

**Problema 3 — falta o estado "logado mas sem paciente"**. Quem acabou de criar conta não tem paciente nenhum e precisa cair no onboarding, não na home.

**Como fica:**

```dart
static GoRouter router(AuthState auth, VinculoState vinc) => GoRouter(
  initialLocation: '/login',
  refreshListenable: Listenable.merge([auth, vinc]),
  routes: [
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/comecar',  builder: (_, __) => const ComecarScreen()),
    GoRoute(path: '/vincular', builder: (_, __) => const VincularScreen()),
    GoRoute(path: '/cadastrar-paciente', builder: (_, __) => const CadastrarPacienteScreen()),
    GoRoute(path: '/inicio',   builder: (_, __) => const HomePorPapel()),
    GoRoute(path: '/equipe',   builder: (_, __) => const EquipeScreen()),
    GoRoute(path: '/historico',builder: (_, __) => const HistoricoScreen()),
    GoRoute(path: '/sos',      builder: (_, __) => const SosScreen()),
  ],
  redirect: (context, state) {
    final indo = state.matchedLocation;
    final publica = indo == '/login' || indo == '/register';

    if (!auth.autenticado) return publica ? null : '/login';

    // Autenticado mas ainda sem paciente vinculado → onboarding
    final noOnboarding = indo == '/comecar' || indo == '/vincular' ||
                         indo == '/cadastrar-paciente';
    if (vinc.ativo == null && !noOnboarding) return '/comecar';

    if (publica) return '/inicio';
    return null;
  },
);
```

E no `main.dart` o router passa a receber os estados.

> A rota `/paciente` some. Ela vira `/inicio`, que escolhe a home conforme o papel.

---

### 2.3 🔴 `lib/models/app_state.dart`

Este arquivo tem **o antipadrão central** que precisa sair:

```dart
String _perfil = '';
void login(String p) { _logado = true; _perfil = p; }
```

O perfil está guardado como texto no usuário. Isso é exatamente o que a seção 7.1 do CLAUDE.md proíbe: **o papel pertence à relação com um paciente, não à pessoa**.

**O que fazer:**

| Trecho | Destino |
|---|---|
| `_logado`, `_perfil`, `login()`, `logout()` | **Apagar.** Vai para o `AuthState` |
| `paciente` (vindo do MockData) | **Apagar.** Vem do `VinculoState` |
| `_remedios`, `toggleRemedio`, `addRemedio`, `removeRemedio` | **Mover** para `CuidadoState`, com chamada à API |
| `_msgs`, `mensagens()`, `addMensagem()` | **Manter** por enquanto — o chat pode ficar local até sobrar tempo |
| `acionarSos()` | **Manter** |

A boa notícia: **os nomes dos métodos continuam iguais**. As telas que chamam `toggleRemedio` não precisam mudar de assinatura, só passam a esperar `Future`.

```dart
// antes
void toggleRemedio(String id) { ... }

// depois
Future<void> confirmarDose(int doseId) async {
  await Api.post('/pacientes/$pacienteId/doses/$doseId/confirmar');
  await carregarDosesDeHoje();
}
```

---

### 2.4 🔴 `lib/screens/auth/login_screen.dart`

**Hoje** o login é falso:

```dart
await Future.delayed(const Duration(milliseconds: 600));
context.read<AppState>().login('paciente');
context.go('/paciente');
```

**Precisa** chamar a API de verdade. O visual fica igual, só o `_entrar()` muda:

```dart
Future<void> _entrar() async {
  if (_emailCtrl.text.isEmpty || _senhaCtrl.text.isEmpty) {
    setState(() => _erro = 'Preencha email e senha.');
    return;
  }
  final auth = context.read<AuthState>();
  final ok = await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);
  if (!mounted) return;
  if (!ok) {
    setState(() => _erro = auth.erro);
    return;
  }
  await context.read<VinculoState>().carregar();
  if (!mounted) return;
  context.go(context.read<VinculoState>().vazio ? '/comecar' : '/inicio');
}
```

Troque também os valores de teste `gustavo@exemplo.com` por um usuário que exista no seu banco.

---

### 2.5 🔴 `lib/screens/auth/perfil_screen.dart`

Esta é a tela que pergunta "Familiar / Cuidador / Paciente". E o próprio código já denuncia o problema:

```dart
// Por ora, independente do perfil, vai para tela do paciente
context.go('/paciente');
```

Ou seja: a pergunta é feita e a resposta é **ignorada**.

**Precisa virar** `comecar_screen.dart`, com as três ações:

| Opção | Rota | Consequência |
|---|---|---|
| Vou cuidar de alguém | `/cadastrar-paciente` | vira **administrador** do paciente |
| Recebi um convite | `/vincular` | papel **vem do convite** |
| O cuidado é para mim | `/cadastrar-paciente?eu=1` | vira **paciente** do próprio perfil |

O layout dos três cartões pode ser reaproveitado quase inteiro — muda o texto e o destino.

---

### 2.6 🟡 `lib/screens/auth/cadastrar_paciente_screen.dart`

**Hoje** provavelmente só navega. **Precisa** chamar `VinculoState.cadastrarPaciente()`, que cria o paciente na API e já define o usuário como administrador.

Acrescente o aviso no fim do formulário:

> Ao cadastrar, você se torna **administradora** deste perfil: só você convida e remove quem tem acesso.

---

### 2.7 🔴 `lib/screens/paciente/paciente_home.dart`

**Hoje** a navegação inferior é fixa do paciente: Chat · Atividades · [centro] · Remédios · SOS.

**Precisa** virar `HomePorPapel`, que escolhe a home e as abas conforme `VinculoState.navegacao`:

```dart
class HomePorPapel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    switch (context.watch<VinculoState>().navegacao) {
      case 'cuidador': return const CuidadorHome();
      case 'paciente': return const PacienteHome();
      default:         return const FamiliarHome();
    }
  }
}
```

As abas por papel:

| Papel | Abas |
|---|---|
| Paciente | Início · Atividades · **[Milo]** · Remédios · SOS |
| Cuidador | Início · Pacientes · **[Milo]** · Tarefas · SOS |
| Familiar | Início · Histórico · **[Milo]** · Tarefas · SOS |

O componente `_BottomNav` que já existe serve de base — extraia para `widgets/nav_por_papel.dart` recebendo a lista de itens.

---

### 2.8 🟡 `lib/screens/paciente/tabs/remedios_tab.dart`

Boa notícia: a estrutura está certa. Ela já usa `context.watch<AppState>().remedios` e `context.read<AppState>().toggleRemedio(r.id)`.

**Muda pouco:**
- Trocar `AppState` por `CuidadoState`
- Envolver a lista em um `FutureBuilder` ou usar o `carregando` do state
- Adicionar estado vazio: *"Cadastre o primeiro remédio — assim o Milo passa a lembrar dos horários"*
- Agrupar por período do dia (Manhã / Tarde / Noite)

---

### 2.9 🔴 `lib/services/gemini_service.dart`

**Três problemas graves:**

1. **A chave está no código do app** (`_apiKey = 'COLOQUE SUA CHAVE...'`). App distribuído é extraível — qualquer pessoa recupera a chave do APK.
2. **`BLOCK_NONE` nas quatro categorias de segurança**, num app de saúde para idosos. Indefensável em banca.
3. **Dados sensíveis indo direto para o Google**: o prompt monta nome, idade, condição, alergias e tipo sanguíneo do paciente e envia do celular.

**Solução:** mover para o backend.

```
backend/src/controllers/miloController.js   → POST /milo
```

- Chave em `process.env.GEMINI_API_KEY`
- `BLOCK_MEDIUM_AND_ABOVE` nos safety settings
- Contexto mínimo: primeiro nome e lista de medicamentos do dia. **Sem** tipo sanguíneo, sem documento, sem histórico completo
- As três recusas obrigatórias: dose, diagnóstico, decidir se é emergência

No Flutter, `gemini_service.dart` vira uma chamada a `Api.post('/milo', {...})`. Some o `http` direto, some a chave, some o prompt.

Também remova os `print()` de depuração — tem vários no arquivo.

---

### 2.10 🟡 `lib/theme/app_theme.dart`

As cores atuais **não são as do design v3**:

| Token | Hoje | Design v3 |
|---|---|---|
| primary | `#3A8F85` | `#3E7C76` |
| background | `#F7F9F9` | `#F0F2F1` |
| — | `accent #F4A261` (laranja) | `#F2C744` (amarelo de atenção) |
| — | `accentPink #E07F9C` | não existe |
| error | `#E57373` | `sos #C25B4E` |

**Precisa:** substituir pela escala completa da seção 4 do CLAUDE.md e remover `accentPink`. A regra do design é que amarelo só significa atenção e terracota é exclusivo do SOS — cor rosa decorativa quebra isso.

---

### 2.11 🟡 `lib/models/models.dart`

Os modelos foram feitos para dados falsos e precisam casar com a API:

| Classe | Problema | Correção |
|---|---|---|
| `Remedio` | tem `tomado` (bool) mas não tem id da dose nem horário previsto/efetivo | Separar em `Medicamento` e `Dose` |
| `Paciente` | `dataNascimento` como `String` | `DateTime?` |
| `Paciente` | `id` como `String` | `int` (o banco usa SERIAL) |
| todas | sem `fromJson` | adicionar em todas |

---

### 2.12 🟢 `lib/data/mock_data.dart`

Depois que tudo estiver na API, este arquivo **some**. Até lá, use como seed para popular o banco de teste.

---

## Parte 3 — Telas que faltam

| Tela | Prioridade | Por quê |
|---|---|---|
| **Equipe** (código, convite, aprovação, revogação) | 🔴 alta | É um dos dois momentos fortes do vídeo |
| **Histórico** (linha do tempo) | 🔴 alta | Prova que o registro funciona |
| Home do cuidador (agenda do turno) | 🟡 média | Demonstra o segundo perfil |
| Home do familiar (resumo em uma frase) | 🟡 média | Demonstra o terceiro perfil |
| Vincular por código | 🟡 média | Fecha o onboarding por ação |
| Relatório, Agenda, Planos, Config, Ajuda | 🟢 baixa | Deixe no protótipo HTML se faltar tempo |

---

## Parte 4 — Ordem de execução

Cada bloco é um comando para o Claude Code. **Teste e commite entre eles.**

**Bloco 1 — fundação**
```
Leia o CLAUDE.md e o MODIFICACOES_HumanaCare.md.
Execute as partes 0 e 2.1: limpeza do repositório e registro dos três
estados no main.dart. Não altere nenhuma tela ainda.
```

**Bloco 2 — rotas**
```
Execute a parte 2.2: reescreva o app_router.dart com refreshListenable,
AuthState no lugar de AppState, e o estado "autenticado sem paciente".
```

**Bloco 3 — login real**
```
Execute a parte 2.4: ligue a login_screen.dart ao AuthState.
Mantenha o visual exatamente como está.
```

**Bloco 4 — onboarding por ação**
```
Execute as partes 2.5 e 2.6: transforme perfil_screen.dart em
comecar_screen.dart com as três ações, e ligue o cadastro de paciente
ao VinculoState.
```

**Bloco 5 — o caminho crítico**
```
Execute as partes 2.3 e 2.8: crie o CuidadoState com as chamadas reais
de doses, e ligue a remedios_tab.dart nele. Inclua o estado vazio.
```

**Bloco 6 — navegação por papel**
```
Execute a parte 2.7: HomePorPapel e nav_por_papel.dart.
Crie as homes do cuidador e do familiar.
```

**Bloco 7 — equipe e revogação**
```
Crie a equipe_screen.dart com código do paciente, pedido de acesso,
aprovação e revogação. Só o administrador vê os botões de gestão.
```

**Bloco 8 — Milo seguro**
```
Execute a parte 2.9: mova a chamada do Gemini para o backend com as
três recusas obrigatórias.
```

**Bloco 9 — tema**
```
Execute a parte 2.10: substitua as cores pela escala da seção 4 do CLAUDE.md.
```

### Ao fim de cada bloco

```
Revise o que você acabou de escrever contra a seção 12 do CLAUDE.md,
item por item. Liste o que está violando e corrija.
```

```bash
flutter analyze
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
git add . && git commit -m "bloco N: ..."
```

---

## Parte 5 — Checklist final

**Repositório**
- [ ] `.dart_tool copy` fora do versionamento
- [ ] `.gitignore` correto
- [ ] Sem `print()` no código
- [ ] `flutter analyze` sem erros
- [ ] README com passo a passo para rodar

**Segurança**
- [ ] Nenhuma chave de API no código do app
- [ ] Gemini pelo backend, com `BLOCK_MEDIUM_AND_ABOVE`
- [ ] Contexto minimizado no prompt
- [ ] `.env` fora do Git

**Funcional**
- [ ] Login real, sessão persiste ao reabrir
- [ ] Cadastrar paciente → vira administrador
- [ ] Remédios do dia vindos da API
- [ ] **Confirmar dose grava no banco**
- [ ] Histórico mostra o registro
- [ ] Revogar acesso corta na hora
- [ ] Milo recusa pergunta sobre dose

**Produto**
- [ ] Papel lido do vínculo, nunca do usuário
- [ ] Navegação muda conforme o papel
- [ ] Selo do vínculo na home
- [ ] Toda tela com estado vazio
- [ ] Cores do design v3
- [ ] Toque de 44px, fonte mínima 12px

---

## Se o tempo apertar

Corte nesta ordem, sem dó:

1. Home do familiar e do cuidador → demonstre só o paciente
2. Equipe no Flutter → demonstre no protótipo HTML
3. Milo no Flutter → demonstre no HTML
4. Tema v3 → as cores atuais não são erradas, só diferentes

**O que não pode faltar:** login → cadastrar paciente → confirmar dose → dado aparecendo no banco em nuvem.
