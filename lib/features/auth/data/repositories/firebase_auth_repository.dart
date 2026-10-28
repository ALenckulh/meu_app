import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/shared/models/professor.dart';

/// Auth + perfil em Realtime Database (`professores/{uid}`).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    this.firebaseAuth,
    FirebaseDatabase? database,
  }) : _db = database ?? FirebaseDatabase.instance;

  final FirebaseAuth? firebaseAuth;
  final FirebaseDatabase _db;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  Future<Professor?> _loadProfessor(User user) async {
    final DataSnapshot snap =
        await _db.ref(RtdbPaths.professor(user.uid)).get();
    if (snap.exists && snap.value != null) {
      return Professor.fromMap(
        user.uid,
        Map<dynamic, dynamic>.from(snap.value as Map),
      );
    }
    return Professor(
      id: user.uid,
      nome: (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Professor'),
      email: user.email ?? '',
    );
  }

  @override
  Professor? get currentUser {
    if (firebaseAuth == null && Firebase.apps.isEmpty) {
      return null;
    }
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return Professor(
      id: user.uid,
      nome: (user.displayName != null && user.displayName!.trim().isNotEmpty)
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Professor'),
      email: user.email ?? '',
    );
  }

  @override
  Future<Professor?> login(String email, String senha) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final User? user = credential.user;
      if (user == null) {
        return null;
      }
      return await _loadProfessor(user);
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

    final User user = credential.user!;
    await user.updateDisplayName(nome);

    final Professor professor = Professor(
      id: user.uid,
      nome: nome,
      email: email,
    );
    await _db.ref(RtdbPaths.professor(user.uid)).set(professor.toMap());

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
