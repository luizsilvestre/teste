import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicamento.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'validade.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS medicamentos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              produto TEXT NOT NULL,
              lote TEXT NOT NULL,
              dataVencimento TEXT NOT NULL,
              criadoEm TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (e) {
      print('Erro ao inicializar BD: $e');
      rethrow;
    }
  }

  Future<int> inserir(Medicamento medicamento) async {
    try {
      final db = await database;
      return await db.insert('medicamentos', medicamento.toMap());
    } catch (e) {
      print('Erro ao inserir: $e');
      rethrow;
    }
  }

  Future<List<Medicamento>> buscarTodos() async {
    try {
      final db = await database;
      final result = await db.query('medicamentos');
      return result.map((map) => Medicamento.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar: $e');
      return [];
    }
  }

  Future<int> deletar(int id) async {
    try {
      final db = await database;
      return await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Erro ao deletar: $e');
      rethrow;
    }
  }
}
