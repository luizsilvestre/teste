import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'cooperpedidos.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            origem TEXT,
            filial TEXT,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE itens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pedido_id INTEGER,
            codigo TEXT,
            nome TEXT,
            quantidade TEXT,
            unidade TEXT,
            origem TEXT,
            filial TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE itens ADD COLUMN origem TEXT');
          await db.execute('ALTER TABLE itens ADD COLUMN filial TEXT');
        }
      },
    );
  }

  static Future<int> salvarPedido(String origem, String filial) async {
    final database = await db;
    return await database.insert('pedidos', {
      'origem': origem,
      'filial': filial,
      'data': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> salvarItem(int pedidoId, String codigo, String nome, String quantidade, String unidade, {String origem = '', String filial = ''}) async {
    final database = await db;
    await database.insert('itens', {
      'pedido_id': pedidoId,
      'codigo': codigo,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'origem': origem,
      'filial': filial,
    });
  }

  static Future<List<Map<String, dynamic>>> buscarPedidos() async {
    final database = await db;
    return await database.query('pedidos', orderBy: 'id DESC');
  }

  static Future<List<Map<String, dynamic>>> buscarPedidosPorData(DateTime data) async {
    final database = await db;
    String dataInicio = DateTime(data.year, data.month, data.day).toIso8601String();
    String dataFim = DateTime(data.year, data.month, data.day, 23, 59, 59).toIso8601String();
    return await database.query(
      'pedidos',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'id DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> buscarItens(int pedidoId) async {
    final database = await db;
    return await database.query('itens', where: 'pedido_id = ?', whereArgs: [pedidoId]);
  }

  static Future<void> apagarPedido(int pedidoId) async {
    final database = await db;
    await database.delete('itens', where: 'pedido_id = ?', whereArgs: [pedidoId]);
    await database.delete('pedidos', where: 'id = ?', whereArgs: [pedidoId]);
  }
}
