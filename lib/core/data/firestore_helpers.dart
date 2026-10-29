import 'package:cloud_firestore/cloud_firestore.dart';

/// Ordena documentos do mais antigo para o mais novo, pelo campo `criadoEm`.
///
/// Documento recém-criado, com o timestamp do servidor ainda pendente (null),
/// vai para o fim da lista.
int compararPorCriacao(Map<String, dynamic> a, Map<String, dynamic> b) {
  final Timestamp? ta = a['criadoEm'] as Timestamp?;
  final Timestamp? tb = b['criadoEm'] as Timestamp?;
  if (ta == null && tb == null) {
    return 0;
  }
  if (ta == null) {
    return 1;
  }
  if (tb == null) {
    return -1;
  }
  return ta.compareTo(tb);
}

/// Converte um número vindo do Firestore em `int` (na web pode chegar como double).
int paraInt(Object? valor) => (valor as num).toInt();
