import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/shared/models/professor.dart';

/// Implementação do [AuthRepository] integrada ao Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({this.firebaseAuth});

  final FirebaseAuth? firebaseAuth;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  Professor? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }
    return Professor(
      id: user.uid,
      nome: (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Professor'),
      email: user.email ?? '',
      senha: '',
    );
  }

  @override
  Professor? get currentUser {
    if (firebaseAuth == null && Firebase.apps.isEmpty) {
      return null;
    }
    return _mapFirebaseUser(_auth.currentUser);
  }

  @override
  Future<Professor?> login(String email, String senha) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      return _mapFirebaseUser(credential.user);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Professor> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    if (credential.user != null) {
      await credential.user!.updateDisplayName(nome);
      await credential.user!.reload();
    }

    final User? updatedUser = _auth.currentUser;
    final Professor professor = _mapFirebaseUser(updatedUser) ??
        Professor(
          id: credential.user!.uid,
          nome: nome,
          email: email,
          senha: '',
        );

    // Desconecta após o cadastro para permitir login explícito na LoginPage
    await _auth.signOut();

    return professor;
  }

  @override
  Future<void> logout() async {
    if (firebaseAuth != null || Firebase.apps.isNotEmpty) {
      await _auth.signOut();
    }
  }
}
