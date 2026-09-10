import 'package:meu_app/shared/models/questao.dart';

abstract class QuestaoRepository {
  Future<List<Questao>> listAll({String? query});
  Future<Questao?> getById(String id);
  Future<Questao> create(Questao questao);
  Future<Questao> update(Questao questao);
  Future<void> delete(String id);
}
