import 'package:meu_app/core/data/app_mock_store.dart';
import 'package:meu_app/features/questoes/domain/repositories/questao_repository.dart';
import 'package:meu_app/shared/models/questao.dart';
import 'package:uuid/uuid.dart';

class QuestaoMockRepository implements QuestaoRepository {
  QuestaoMockRepository(this._store);

  final AppMockStore _store;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Questao>> listAll({String? query}) async {
    Iterable<Questao> list = _store.questoes;
    if (query != null && query.trim().isNotEmpty) {
      final String q = query.toLowerCase();
      list = list.where((Questao item) {
        return item.enunciado.toLowerCase().contains(q) ||
            item.tags.any((String t) => t.toLowerCase().contains(q));
      });
    }
    return list.toList();
  }

  @override
  Future<Questao?> getById(String id) async {
    try {
      return _store.questoes.firstWhere((Questao q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Questao> create(Questao questao) async {
    final Questao created = questao.copyWith(id: _uuid.v4());
    _store.questoes.add(created);
    return created;
  }

  @override
  Future<Questao> update(Questao questao) async {
    final int index =
        _store.questoes.indexWhere((Questao q) => q.id == questao.id);
    if (index >= 0) {
      _store.questoes[index] = questao;
    }
    return questao;
  }

  @override
  Future<void> delete(String id) async {
    _store.questoes.removeWhere((Questao q) => q.id == id);
  }
}
