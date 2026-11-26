import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/firebase_options.dart';

/// Realtime Database always bound to the API root URL (no child path).
FirebaseDatabase get rtdb => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.databaseURL,
    );

/// Filhos de [ref] cujo campo [campo] vale [valor].
///
/// Usa a consulta indexada (`orderByChild` + `equalTo`). Se o banco
/// publicado ainda não tiver o `.indexOn` desse campo, o Android recusa a
/// consulta ("Index not defined"); nesse caso lê o nó inteiro e filtra no
/// app, para a tela não quebrar. Publique `database.rules.json` para voltar
/// a usar só a consulta indexada.
Future<Map<dynamic, dynamic>> filhosComValor(
  DatabaseReference ref,
  String campo,
  String valor,
) async {
  DataSnapshot snap;
  try {
    snap = await ref.orderByChild(campo).equalTo(valor).get();
  } catch (e) {
    if (!e.toString().contains('Index not defined')) {
      rethrow;
    }
    final DataSnapshot tudo = await ref.get();
    if (!tudo.exists || tudo.value is! Map) {
      return <dynamic, dynamic>{};
    }
    return <dynamic, dynamic>{
      for (final MapEntry<dynamic, dynamic> e
          in (tudo.value! as Map<dynamic, dynamic>).entries)
        if (e.value is Map && (e.value as Map)[campo] == valor) e.key: e.value,
    };
  }
  if (!snap.exists || snap.value is! Map) {
    return <dynamic, dynamic>{};
  }
  return snap.value! as Map<dynamic, dynamic>;
}
