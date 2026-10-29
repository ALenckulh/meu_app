import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:meu_app/core/data/rtdb.dart';
import 'package:meu_app/core/data/rtdb_paths.dart';
import 'package:meu_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_app/shared/models/professor.dart';

/// Auth + perfil em Realtime Database (`professores/{uid}`).
///
/// Sucesso de Auth **não** depende do RTDB: se o perfil falhar (regras/URL),
/// login/cadastro ainda retornam [Professor] a partir do Firebase Auth.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    this.firebaseAuth,
    FirebaseDatabase? database,
  }) : _db = database ?? rtdb;

  final FirebaseAuth? firebaseAuth;
  final FirebaseDatabase _db;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  Professor _fromAuthUser(User user, {String? nomeOverride}) {
    return Professor(
      id: user.uid,
      nome: nomeOverride ??
          ((user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (user.email?.split('@').first ?? 'Professor')),
      email: user.email ?? '',
    );
  }

  /// Best-effort: lê/cria `professores/{uid}`. Erros RTDB são engolidos.
  Future<void> _syncProfessorBestEffort(Professor professor) async {
    try {
      final DatabaseReference ref =
          _db.ref(RtdbPaths.professor(professor.id));
      final DataSnapshot snap = await ref.get();
      if (snap.exists && snap.value != null) {
        return;
      }
      await ref.set(professor.toMap());
    } catch (e, st) {
      debugPrint('RTDB professores sync failed: $e\n$st');
    }
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
    return _fromAuthUser(user);
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
      final Professor professor = _fromAuthUser(user);
      await _syncProfessorBestEffort(professor);
      return professor;
    } on FirebaseAuthException {
      return null;
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

    User user = credential.user!;
    await user.updateDisplayName(nome);
    await user.reload();
    user = _auth.currentUser ?? user;

    final Professor professor = _fromAuthUser(user, nomeOverride: nome);
    await _syncProfessorBestEffort(professor);

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
