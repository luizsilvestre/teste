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

  Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cor TEXT NOT NULL,
        criadoEm TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria_id INTEGER NOT NULL,
        produto TEXT NOT NULL,
        lote TEXT NOT NULL,
        dataVencimento TEXT NOT NULL,
        criadoEm TEXT NOT NULL,
        FOREIGN KEY(categoria_id) REFERENCES categorias(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contatos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        numero TEXT NOT NULL,
        nome TEXT NOT NULL
      )
    ''');
  }

  Future<void> _inserirCategoriasPadrao(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final cat in [
      {'nome': 'Medicamentos', 'cor': '#FF5252'},
      {'nome': 'Ração', 'cor': '#FFA726'},
      {'nome': 'Alimentos', 'cor': '#66BB6A'},
      {'nome': 'Bebidas', 'cor': '#29B6F6'},
    ]) {
      await db.insert('categorias', {...cat, 'criadoEm': now});
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'validade.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await _criarTabelas(db);
          await _inserirCategoriasPadrao(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('DROP TABLE IF EXISTS medicamentos');
            await db.execute('DROP TABLE IF EXISTS categorias');
            await db.execute('DROP TABLE IF EXISTS contatos');
            await _criarTabelas(db);
            await _inserirCategoriasPadrao(db);
          }
        },
      );
    } catch (e) {
      print('Erro ao inicializar BD: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS MEDICAMENTOS =====
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

  Future<List<Medicamento>> buscarPorCategoria(int categoriaId) async {
    try {
      final db = await database;
      final result = await db.query(
        'medicamentos',
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
      );
      return result.map((map) => Medicamento.fromMap(map)).toList();
    } catch (e) {
      print('Erro ao buscar por categoria: $e');
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

  // ===== MÉTODOS CATEGORIAS =====
  Future<List<Map<String, dynamic>>> buscarCategorias() async {
    try {
      final db = await database;
      return await db.query('categorias', orderBy: 'nome ASC');
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }

  Future<int> inserirCategoria(String nome, String cor) async {
    try {
      final db = await database;
      return await db.insert('categorias', {
        'nome': nome,
        'cor': cor,
        'criadoEm': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao inserir categoria: $e');
      rethrow;
    }
  }

  Future<int> atualizarCategoria(int id, String nome, String cor) async {
    try {
      final db = await database;
      return await db.update(
        'categorias',
        {'nome': nome, 'cor': cor},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Erro ao atualizar categoria: $e');
      rethrow;
    }
  }

  Future<int> deletarCategoria(int id) async {
    try {
      final db = await database;
      return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Erro ao deletar categoria: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS CONTATOS =====
  Future<int> inserirContato(String tipo, String numero, String nome) async {
    try {
      final db = await database;
      return await db.insert('contatos', {
        'tipo': tipo,
        'numero': numero,
        'nome': nome,
      });
    } catch (e) {
      print('Erro ao inserir contato: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarContatos() async {
    try {
      final db = await database;
      return await db.query('contatos');
    } catch (e) {
      print('Erro ao buscar contatos: $e');
      return [];
    }
  }

  Future<int> atualizarContato(int id, String numero, String nome) async {
    try {
      final db = await database;
      return await db.update(
        'contatos',
        {'numero': numero, 'nome': nome},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Erro ao atualizar contato: $e');
      rethrow;
    }
  }

  Future<int> deletarContato(int id) async {
    try {
      final db = await database;
      return await db.delete('contatos', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Erro ao deletar contato: $e');
      rethrow;
    }
  }
}
