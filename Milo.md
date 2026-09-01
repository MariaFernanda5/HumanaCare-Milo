# Milo — aplicativo Flutter

Coloque este arquivo na **raiz do repositório do app**. O Claude Code lê ele automaticamente e usa como contexto de todo o projeto.

---

## 1. O que estamos construindo

**Milo** é o aplicativo da startup **HumanaCare**. Ele organiza o cuidado domiciliar de idosos, pessoas com deficiência e pacientes em recuperação.

O problema: o cuidado é feito por várias pessoas que se revezam — filha, cuidadora contratada, irmão que mora longe — e é coordenado por mensagens de WhatsApp, bilhetes e memória. Ninguém sabe se a dose das 20h foi dada.

O Milo resolve isso sendo o registro compartilhado: quem tomou o quê, quando, e quem registrou.

**Posicionamento:** "Todo mundo que cuida, na mesma página."

Projeto acadêmico de TCC (FIAP, Startup One). Precisa rodar de verdade e ser demonstrado em vídeo.

### Os três perfis

| Perfil | Quem é | O que a home dele responde |
|---|---|---|
| **Paciente** | Samuel P., 68 anos | "O que eu preciso fazer agora?" |
| **Cuidador** | Julia M., trabalha por turno, atende mais de um paciente | "O que falta no meu turno?" |
| **Familiar** | Ana Luísa, filha, mora longe | "Está tudo bem?" |

---

## 2. Stack

| Camada | Escolha |
|---|---|
| App | Flutter 3.x · Dart 3.x |
| Estado | `provider` (simples, suficiente, fácil de defender em banca) |
| HTTP | `http` |
| Armazenamento local | `shared_preferences` (token) · `flutter_secure_storage` (se disponível) |
| Notificações | `flutter_local_notifications` |
| Rotas | `go_router` |
| Backend | Node.js + Express **já existe** (ver seção 6) |
| Banco | Azure Database for PostgreSQL |

### Dependências do pubspec

```yaml
dependencies:
  flutter: {sdk: flutter}
  provider: ^6.1.0
  http: ^1.2.0
  go_router: ^14.0.0
  shared_preferences: ^2.2.0
  flutter_local_notifications: ^17.0.0
  intl: ^0.19.0
```

**Não adicione outras dependências sem necessidade real.** Cada pacote a mais é uma coisa a explicar na banca.

---

## 3. Estrutura de pastas

```
lib/
├── main.dart
├── app.dart                  MaterialApp, tema, rotas
├── core/
│   ├── theme.dart            tokens de cor, tipografia, espaçamento
│   ├── api.dart              cliente HTTP, injeção do token, tratamento de erro
│   └── formatters.dart       data, hora, atraso em minutos
├── models/
│   ├── usuario.dart
│   ├── paciente.dart
│   ├── vinculo.dart
│   ├── medicamento.dart
│   ├── dose.dart
│   ├── tarefa.dart
│   └── evento.dart
├── state/
│   ├── auth_state.dart       login, token, usuário atual
│   ├── vinculo_state.dart    paciente ativo e papel — o núcleo do RBAC
│   ├── cuidado_state.dart    doses, tarefas, histórico
│   └── milo_state.dart       conversa com o assistente
├── screens/
│   ├── onboarding/           splash, login, criar conta, começar, vincular, cadastros
│   ├── paciente/
│   ├── cuidador/
│   ├── familiar/
│   ├── comum/                milo, remédios, tarefas, histórico, equipe, sos, config
│   └── estados/              vazio, offline, erro
└── widgets/
    ├── milo_bar.dart         barra do assistente no topo das telas iniciais
    ├── nav_inferior.dart     navegação com o Milo ao centro
    ├── cartao.dart
    ├── pilula.dart           badge de status
    └── selo_vinculo.dart     "Você é administradora do perfil de X"
```

---

## 4. Design system

Use exatamente estes valores. Eles vêm do design v3 aprovado.

### Cores

```dart
// core/theme.dart
class C {
  static const v900 = Color(0xFF173330);  // títulos
  static const v800 = Color(0xFF1F3B38);  // texto
  static const v700 = Color(0xFF2F5F5A);
  static const v600 = Color(0xFF3E7C76);  // PRIMÁRIA — única cor de ação
  static const v500 = Color(0xFF4F8D86);
  static const v400 = Color(0xFF6FA9A2);  // ícone inativo
  static const v300 = Color(0xFF86C5B8);  // avatar, tile
  static const v200 = Color(0xFFB6DAD4);
  static const v100 = Color(0xFFCFE4E1);  // bordas
  static const v50  = Color(0xFFEDF6F4);  // fundo suave
  static const v25  = Color(0xFFF6FAF9);

  static const am     = Color(0xFFF2C744); // atenção
  static const amBg   = Color(0xFFFDF3D8);
  static const amTxt  = Color(0xFF7A6210);
  static const amDark = Color(0xFF4A3A05);

  static const bg     = Color(0xFFF0F2F1);
  static const branco = Color(0xFFFFFFFF);
  static const muted  = Color(0xFF7A918E);
  static const muted2 = Color(0xFF5C807C);

  static const sos    = Color(0xFFC25B4E); // SOMENTE emergência
  static const sosBg  = Color(0xFFFBEAE7);
}
```

### Regras de cor — não negociáveis

- **Verde 600 é a única cor de ação.** Um botão primário por tela.
- **Amarelo nunca é decorativo.** Ele significa "precisa da sua atenção": dose atrasada, sintoma novo, alerta.
- **Terracota é exclusivo do SOS.** Nada mais no app usa vermelho.
- **Campos de formulário são brancos com borda Verde 100.** Nunca preenchidos de verde — bloco verde sólido não é reconhecido como campo editável, principalmente por usuário idoso.
- Verde 50 é fundo de agrupamento. Verde 100 é linha divisória.

### Tipografia

| Uso | Tamanho / peso |
|---|---|
| Título | 24 / w600 |
| Cabeçalho | 17 / w600 |
| Corpo | 15 / w400 |
| Item de lista | 14 / w600 |
| Apoio | 12 / w400 |

**Mínimo absoluto de 12px.** Nada abaixo disso — o usuário paciente tem 68 anos.

### Medidas

- Raio de canto: 12 (cartões e botões), 14 (cartões grandes), 999 (pílulas)
- Área de toque mínima: **44 × 44** — requisito WCAG 2.1 AA
- Espaçamento interno de tela: 18 horizontal, 16 vertical
- Espaço entre cartões: 8

---

## 5. Modelos de dados

Devem espelhar o schema do banco. Todos com `fromJson` e `toJson`.

```dart
class Paciente {
  final int id;
  final String nome;
  final DateTime? dataNascimento;
  final String? condicaoSaude;
  final String? alergias;
  final String? tipoSanguineo;
  final String perfilCuidado; // idoso_dependente | pessoa_com_deficiencia | recuperacao_pos_alta
}

class Vinculo {
  final int pacienteId;
  final String pacienteNome;
  final String papel;         // administrador | cuidador | visualizador | paciente
  final String tipoCuidador;  // formal | informal | profissional_saude
  final bool ativo;
}

class Medicamento {
  final int id;
  final String nome;
  final String? dosagem;
  final String? forma;
  final String? instrucoes;
  final bool usoContinuo;
  final List<String> horarios; // "08:00"
}

class Dose {
  final int id;
  final int medicamentoId;
  final String nome;
  final String? dosagem;
  final DateTime horarioPrevisto;
  final DateTime? horarioEfetivo;
  final String status; // pendente | administrada | nao_administrada | atrasada

  int? get atrasoMinutos => horarioEfetivo == null
      ? null
      : horarioEfetivo!.difference(horarioPrevisto).inMinutes;
}

class Tarefa {
  final int id;
  final String titulo;
  final String? descricao;
  final String? categoria;
  final String prioridade;  // alta | media | baixa
  final String recorrencia;
  final int? responsavelId;
  final String? responsavelNome;
  final DateTime? prazo;
  final DateTime? concluidaEm;
  final String status;      // pendente | concluida | atrasada | cancelada
}

class Evento {           // linha do tempo do histórico
  final int id;
  final String tipoEvento;
  final String descricao;
  final String canal;    // app_mobile | painel_web | assistente_milo | automatico
  final DateTime ocorridoEm;
  final String? usuarioNome;
}
```

---

## 6. Contrato da API

O backend **já está escrito** (Node.js + Express + PostgreSQL). Não reescreva — consuma.

Base URL em variável de ambiente. Todas as rotas abaixo de `/pacientes` exigem `Authorization: Bearer <token>`.

### Autenticação

| Método | Rota | Corpo | Retorno |
|---|---|---|---|
| POST | `/users/register` | `{nome, email, senha}` | usuário criado |
| POST | `/users/login` | `{email, senha}` | `{token}` |
| GET | `/users/profile` | — | `{userId}` |

### Pacientes

| Método | Rota | Papel |
|---|---|---|
| POST | `/pacientes` | autenticado — quem cria vira administrador |
| GET | `/pacientes` | autenticado — lista os pacientes vinculados |

### Medicamentos e doses

| Método | Rota | Papel |
|---|---|---|
| GET | `/pacientes/:id/medicamentos` | qualquer vínculo |
| POST | `/pacientes/:id/medicamentos` | administrador, cuidador |
| GET | `/pacientes/:id/medicamentos/hoje` | qualquer vínculo |
| POST | `/pacientes/:id/doses/:doseId/confirmar` | administrador, cuidador |
| GET | `/pacientes/:id/adesao` | qualquer vínculo |

### Tarefas

| Método | Rota | Papel |
|---|---|---|
| GET | `/pacientes/:id/tarefas?status=pendente` | qualquer vínculo |
| POST | `/pacientes/:id/tarefas` | administrador, cuidador |
| PATCH | `/pacientes/:id/tarefas/:tarefaId/concluir` | administrador, cuidador |
| GET | `/pacientes/:id/distribuicao` | qualquer vínculo |

### Histórico e equipe

| Método | Rota | Papel |
|---|---|---|
| GET | `/pacientes/:id/historico?desde=&limite=` | qualquer vínculo |
| POST | `/pacientes/:id/cuidadores` | **administrador** |
| DELETE | `/pacientes/:id/cuidadores/:usuarioId` | **administrador** |

### Tratamento de erro

| Código | O que mostrar |
|---|---|
| 401 | Sessão expirada → volta para o login |
| 403 | "Seu perfil não permite esta ação" |
| 404 | "Paciente não encontrado" — o backend usa 404 em vez de 403 para não revelar existência de pacientes de terceiros |
| 409 | "Essa dose já foi confirmada" |
| 5xx | "Não conseguimos conectar. Tente de novo." + botão de repetir |

Nunca mostre a mensagem crua da exceção ao usuário.

---

## 7. Regras invioláveis

Estas cinco regras não podem ser quebradas em nenhuma tela. São o que diferencia o produto.

### 7.1 A permissão é por paciente, não por conta

O papel **não** é uma propriedade da pessoa. É da relação dela com um paciente. A mesma usuária pode ser administradora do perfil da mãe e visualizadora do perfil do sogro.

O `VinculoState` guarda o paciente ativo e o papel nele. **Toda tela lê o papel dali**, nunca de um campo no usuário.

A navegação inferior também decorre do papel:

```dart
const mapaNav = {
  'administrador': 'familiar',
  'visualizador':  'familiar',
  'cuidador':      'cuidador',
  'paciente':      'paciente',
};
```

### 7.2 O papel é derivado, nunca declarado

**Não pergunte "você é familiar, cuidador ou paciente?".** A pessoa erra a resposta — uma filha que cuida da mãe é as duas coisas.

Pergunte a ação:

| Escolha | Consequência |
|---|---|
| "Vou cuidar de alguém" | Cadastra o paciente → **vira administrador dele** |
| "Recebi um convite" | Digita o código de 4 dígitos → **o papel vem do convite** |
| "O cuidado é para mim" | Cadastra os próprios dados → **vira paciente do perfil** |

Depois disso, um selo no topo da home mostra o vínculo: *"Você é administradora do perfil de Samuel P."*

### 7.3 O que o Milo nunca decide sozinho

O assistente **precisa recusar** três coisas, sempre:

1. Dose, troca ou suspensão de medicamento
2. Diagnóstico ou interpretação de exame
3. Decidir sozinho se a situação é uma emergência

Nesses casos ele **registra a ocorrência, avisa um humano da equipe e oferece o botão SOS**. Nunca responde a pergunta.

A chamada ao modelo de linguagem passa **pelo backend**, nunca direto do app. A chave de API não pode existir no código do cliente — aplicativo distribuído é extraível.

Envie o mínimo de contexto: primeiro nome e lista de medicamentos do dia. **Não envie** documento, endereço, tipo sanguíneo ou histórico clínico completo.

### 7.4 Toda conversa vira registro visível

Quando o Milo interpreta uma fala e age ("já tomei a vitamina" → marca a dose), ele **mostra um cartão do que foi registrado, com botão Desfazer**.

Sem isso a IA vira caixa-preta. E ninguém confia numa caixa-preta com medicamento controlado.

### 7.5 Acessibilidade é requisito, não refinamento

- Contraste mínimo 4,5:1 (WCAG 2.1 AA)
- Toque de 44 × 44 no mínimo
- Texto redimensionável sem quebrar layout — respeite o `textScaleFactor` do sistema
- `Semantics` em todo botão só de ícone
- Nenhuma informação transmitida apenas por cor
- Confirmação explícita em ação crítica (confirmar dose, revogar acesso)

---

## 8. Telas

### Onboarding (sem navegação inferior)

| Tela | Conteúdo |
|---|---|
| Splash | Logo, "Milo — cuidado que conecta", máximo 2s |
| Login | E-mail, senha, biometria como atalho, criar conta |
| Criar conta | 3 etapas com indicador de progresso; etapa 1 = dados de acesso + aceite da política |
| Começar | As três ações da regra 7.2 |
| Vincular paciente | Código de 4 dígitos, mostra quem convidou e qual será o papel antes de aceitar |
| Cadastrar paciente | Dados básicos e saúde, separados por divisória. Alergias com aviso de que aparecem na emergência |
| Meus dados | Versão reduzida do anterior, quando o cuidado é para si |

### Navegação inferior

O **Milo é o botão central em todos os perfis** — é o diferencial do produto e fica sempre a um toque.

| Perfil | Abas |
|---|---|
| Paciente | Início · Atividades · **[Milo]** · Remédios · SOS |
| Cuidador | Início · Pacientes · **[Milo]** · Tarefas · SOS |
| Familiar | Início · Histórico · **[Milo]** · Tarefas · SOS |

A aba SOS usa amarelo sobre o verde da barra, para se destacar sem competir com a ação primária.

### Home de cada perfil

**Paciente** — responde "o que fazer agora". Barra do Milo no topo. Três números (remédios, tarefas, alertas). Cartão grande da próxima dose com botão "Tomei". Linha do tempo do resto do dia. Sem calendário mensal na home.

**Cuidador** — a agenda do turno. Progresso em porcentagem. Cartão "Agora" com a tarefa atual e botões Concluir / Adiar. Lista dos pacientes do dia.

**Familiar** — o estado em uma frase, escrita pelo Milo a partir dos registros, com a hora da última atualização e quem registrou. Depois os números e a linha do tempo.

### Telas comuns

Milo (chat) · Remédios agrupados por período do dia · Adicionar medicamento · Tarefas com concluídas colapsadas · Histórico com gráfico de adesão · Relatório para o médico · Equipe com código e aprovação de pedido · Agenda · Notificações separadas por urgência · SOS com contagem regressiva cancelável · Planos · Configurações com acessibilidade no topo · Ajuda com caminho para atendimento humano.

### Estados que não podem faltar

| Estado | Comportamento |
|---|---|
| **Vazio** | Convite com próximo passo claro. Nunca "nada por aqui". Ex.: "Cadastre o primeiro remédio — assim o Milo passa a lembrar dos horários" |
| **Offline** | Barra amarela no topo: "Sem internet · N registros aguardando". Registrar dose e tarefa **continua funcionando** e sincroniza depois. Chat e relatório exigem conexão |
| **Erro** | Mensagem em linguagem simples + botão de repetir |
| **Carregando** | Skeleton, não spinner no meio da tela vazia |

---

## 9. Notificação de dose — o fluxo mais importante

É a ação mais frequente do produto e a razão de ser um app nativo em vez de site.

```
Notificação "Hora do remédio: Losartana 50mg"
   └─ toque
       └─ abre DIRETO na tela da dose (não na home)
           ├─ "JÁ TOMEI"  → POST /doses/:id/confirmar → registra e volta
           └─ "NÃO TOMOU" → pede motivo → registra → alerta o administrador
```

**Dois toques da notificação até a confirmação.** Use `flutter_local_notifications` com agendamento local, para que o lembrete dispare mesmo sem conexão ou com o servidor fora do ar.

---

## 10. Ordem de construção

Não construa tudo de uma vez. Nesta ordem, testando a cada etapa:

**Etapa 1 — fundação**
Tema com os tokens, cliente de API com injeção de token, modelos, `AuthState` e `VinculoState`, login funcionando de ponta a ponta contra o backend.

**Etapa 2 — o caminho crítico**
Onboarding por ação → cadastrar paciente → home do familiar → remédios → **confirmar dose** → histórico registrando. Esse é o fluxo que precisa estar impecável no vídeo.

**Etapa 3 — os outros perfis**
Navegação por papel, home do cuidador, home do paciente, tarefas.

**Etapa 4 — equipe e segurança**
Código do paciente, pedido de acesso, aprovação, **revogação com corte imediato**. Verificar que o cuidador não vê os botões de convidar.

**Etapa 5 — Milo**
Chat consumindo o endpoint do backend, com os três limites da regra 7.3 e o cartão de registro com Desfazer.

**Etapa 6 — notificações e offline**
Agendamento local das doses, fila de sincronização, barra de offline.

**Etapa 7 — o resto**
Atividades, relatório, agenda, planos, configurações, ajuda.

---

## 11. Definição de pronto

Uma tela só está pronta quando:

- [ ] Funciona com dados reais da API, sem mock
- [ ] Tem estado vazio, de carregamento e de erro
- [ ] Respeita o papel do vínculo — testado com administrador, cuidador e visualizador
- [ ] Área de toque de 44px nos botões
- [ ] Legível com o texto do sistema ampliado
- [ ] Botões só de ícone têm `Semantics`
- [ ] Nenhuma cor fora dos tokens
- [ ] Nenhuma string de erro crua aparece para o usuário

---

## 12. O que não fazer

- **Não** coloque chave de API no código do app
- **Não** guarde papel no objeto do usuário — ele pertence ao vínculo
- **Não** pergunte a identidade da pessoa no cadastro
- **Não** deixe o Milo responder sobre dose, diagnóstico ou emergência
- **Não** use vermelho fora do SOS
- **Não** use fonte abaixo de 12px
- **Não** preencha campo de formulário com verde sólido
- **Não** crie tela sem estado vazio
- **Não** adicione dependência que não seja necessária
- **Não** deixe `print()` no código entregue

---

## 13. Contexto para a banca

Coisas que o código precisa poder demonstrar ao vivo, porque são os argumentos do trabalho:

1. **Confirmar uma dose** e mostrar o registro chegando no banco em nuvem
2. **Revogar o acesso** de uma cuidadora e mostrar que ela perde a visibilidade na hora
3. **O Milo recusando** uma pergunta sobre dose e escalando para humano
4. **O modo paciente**, com botão grande e SOS sempre visível
5. **O app funcionando offline** e sincronizando depois

Se precisar cortar escopo por prazo, corte Atividades, Planos e Agenda antes de qualquer um desses cinco.
