import '../database/database_helper.dart';
import '../models/transacao.dart';

/// ABSTRAÇÃO (Interface de Repositório):
/// Desacopla as telas da tecnologia de banco de dados utilizada.
abstract class ITransacaoRepository {
  Future<int> inserir(Transacao transacao);
  Future<List<Transacao>> listarTodas();
  Future<int> atualizar(Transacao transacao);
  Future<int> excluir(int id);
}

/// Implementação concreta utilizando SQLite
class SqliteTransacaoRepository implements ITransacaoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<int> inserir(Transacao transacao) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tabelaTransacoes,
      transacao.toMap(),
    );
  }

  @override
  Future<List<Transacao>> listarTodas() async {
    final db = await _dbHelper.database;
    final registros = await db.query(
      DatabaseHelper.tabelaTransacoes,
      orderBy: 'data DESC, id DESC',
    );

    // Converte cada linha do banco em um objeto polimórfico (TransacaoNacional ou Internacional)
    return registros.map((map) => Transacao.fromMap(map)).toList();
  }

  @override
  Future<int> atualizar(Transacao transacao) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tabelaTransacoes,
      transacao.toMap(),
      where: 'id = ?',
      whereArgs: [transacao.id],
    );
  }

  @override
  Future<int> excluir(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tabelaTransacoes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}