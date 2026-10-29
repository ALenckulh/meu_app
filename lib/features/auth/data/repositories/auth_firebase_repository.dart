import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/shared/models/professor.dart';

/// Autenticação real com Firebase Auth (e-mail e senha).
///
/// A senha só trafega para o Firebase: o app não guarda nem grava a senha.
/// O perfil do professor (nome e e-mail) fica em `professores/{uid}` no Firestore.
class AuthFirebaseRepository implements AuthRepository {
  AuthFirebaseRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Professor? get currentUser {
    final User? user = _auth.currentUser;
    return user == null ? null : _toProfessor(user);
  }

  @override
  Future<Professor?> login(String email, String senha) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final User? user = cred.user;
      return user == null ? null : _toProfessor(user);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        // Mesma resposta para "e-mail não existe" e "senha errada",
        // para não revelar quais e-mails têm conta.
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return null;
        default:
          throw AuthFailure(_mensagem(e.code));
      }
    }
  }

  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final User user = cred.user!;
      final String nomeLimpo = nome.trim();
      try {
        await user.updateDisplayName(nomeLimpo);
        // Perfil no Firestore: nunca inclui a senha.
        await _firestore.collection('professores').doc(user.uid).set(
          <String, dynamic>{
            'nome': nomeLimpo,
            'email': user.email ?? email.trim(),
            'criadoEm': FieldValue.serverTimestamp(),
          },
        );
      } on FirebaseException {
        // A conta já foi criada; falha ao gravar o perfil não deve
        // impedir o cadastro.
      } finally {
        // Mantém o fluxo do N1: depois de criar a conta, o professor entra pelo login.
        await _auth.signOut();
      }
      return Professor(
        id: user.uid,
        nome: nomeLimpo,
        email: user.email ?? email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensagem(e.code));
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  Professor _toProfessor(User user) {
    final String email = user.email ?? '';
    final String? nomePerfil = user.displayName?.trim();
    final String nome = (nomePerfil != null && nomePerfil.isNotEmpty)
        ? nomePerfil
        : (email.contains('@') ? email.split('@').first : 'Professor');
    return Professor(id: user.uid, nome: nome, email: email);
  }

  String _mensagem(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha fraca. Use ao menos 8 caracteres, com letras e números.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique a rede e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'operation-not-allowed':
        return 'Login por e-mail e senha não está ativado no Firebase.';
      default:
        return 'Não foi possível concluir a operação. Tente novamente.';
    }
  }
}
