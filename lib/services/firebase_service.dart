import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String senha,
  }) async {
    try {
      final emailNormalizado = email.trim();
      print('FirebaseService: tentativa de login para $emailNormalizado');

      final credentials = await _auth.signInWithEmailAndPassword(
        email: emailNormalizado,
        password: senha.trim(),
      );

      print('FirebaseService: login realizado com sucesso uid=${credentials.user?.uid}');

      try {
        final existeNoFirestore = await existeUsuarioComEmail(emailNormalizado);
        if (!existeNoFirestore) {
          print('FirebaseService: usuário autenticado sem documento no Firestore; criando registro mínimo');
          final uid = credentials.user?.uid;
          if (uid != null) {
            await _firestore.collection('usuarios').doc(uid).set({
              'uid': uid,
              'nome': credentials.user?.displayName ?? 'Usuário',
              'email': emailNormalizado.toLowerCase(),
              'criadoEm': FieldValue.serverTimestamp(),
              'atualizadoEm': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      } on FirebaseException catch (e) {
        print('FirebaseService: Firestore indisponível após login -> ${e.code}: ${e.message}');
      }

      return credentials;
    } on FirebaseAuthException catch (e) {
      print('FirebaseService: erro de autenticação no login -> ${e.code}: ${e.message}');
      throw _authExceptionMessage(e);
    } catch (e) {
      print('FirebaseService: erro inesperado no login -> $e');
      throw Exception('Email ou senha inválidos');
    }
  }

  static Future<UserCredential> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    String? dataNascimento,
    String? alergias,
    String? medicamentos,
    String? condicaoSaude,
    String? observacoes,
  }) async {
    try {
      final emailNormalizado = email.trim();
      print('FirebaseService: início do cadastro para $emailNormalizado');

      final credentials = await _auth.createUserWithEmailAndPassword(
        email: emailNormalizado,
        password: senha.trim(),
      );

      final uid = credentials.user?.uid;
      if (uid == null) {
        print('FirebaseService: cadastro falhou - UID nulo');
        throw Exception('Usuário não foi criado corretamente.');
      }

      await credentials.user?.updateDisplayName(nome.trim());

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nome': nome.trim(),
        'email': emailNormalizado.toLowerCase(),
        'dataNascimento': dataNascimento?.trim(),
        'alergias': alergias?.trim() ?? '',
        'medicamentos': medicamentos?.trim() ?? '',
        'condicaoSaude': condicaoSaude?.trim() ?? '',
        'observacoes': observacoes?.trim() ?? '',
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FirebaseService: cadastro salvo com sucesso uid=$uid');
      return credentials;
    } on FirebaseAuthException catch (e) {
      print('FirebaseService: erro de autenticação no cadastro -> ${e.code}: ${e.message}');
      throw _authExceptionMessage(e);
    } on FirebaseException catch (e) {
      print('FirebaseService: erro ao salvar dados do paciente -> ${e.code}: ${e.message}');
      throw Exception('Erro ao salvar dados do usuário: ${e.message}');
    } catch (e) {
      print('FirebaseService: erro inesperado no cadastro -> $e');
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  static Future<void> atualizarDadosPaciente({
    required String uid,
    String? nome,
    String? dataNascimento,
    String? alergias,
    String? medicamentos,
    String? condicaoSaude,
    String? observacoes,
  }) async {
    try {
      final data = <String, dynamic>{
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (nome != null && nome.trim().isNotEmpty) data['nome'] = nome.trim();
      if (dataNascimento != null) data['dataNascimento'] = dataNascimento.trim();
      if (alergias != null) data['alergias'] = alergias.trim();
      if (medicamentos != null) data['medicamentos'] = medicamentos.trim();
      if (condicaoSaude != null) data['condicaoSaude'] = condicaoSaude.trim();
      if (observacoes != null) data['observacoes'] = observacoes.trim();

      await _firestore.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Erro ao atualizar dados do paciente: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>?> getDadosUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar dados do usuário: ${e.message}');
    }
  }

  static Future<bool> existeUsuarioComEmail(String email) async {
    try {
      final query = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao consultar usuário no Firebase: ${e.message}');
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static String _authExceptionMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'operation-not-allowed':
        return 'Operação não permitida no momento.';
      default:
        return 'Erro inesperado de autenticação: ${e.message ?? e.code}';
    }
  }
}
