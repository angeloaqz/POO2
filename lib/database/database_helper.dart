import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  // Padrão Singleton: garante apenas uma instância aberta do banco de dados
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String tabelaTransacoes = 'transacoes';

  static const String scriptCriacaoTabela = '''
    CREATE TABLE $tabelaTransacoes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      categoria TEXT NOT NULL,
      valor_original REAL NOT NULL,
      moeda TEXT NOT NULL,
      tipo TEXT NOT NULL,
      data TEXT NOT NULL
    )
  ''';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _inicializarBanco();
    return _database!;
  }

  Future<Database> _inicializarBanco() async {
    final caminhoCompleto = kIsWeb
    ? 'smart_finance.db'
    : join(await getDatabasesPath(), 'smart_finance.db');

    return await openDatabase(
      caminhoCompleto,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(scriptCriacaoTabela);
      },
    );
  }
}