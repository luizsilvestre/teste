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
      version: 1,
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
            unidade TEXT
          )
        ''');
      },
    );
  }

  // Salvar pedido
  static Future<int> salvarPedido(String origem, String filial) async {
    final database = await db;
    return await database.insert('pedidos', {
      'origem': origem,
      'filial': filial,
      'data': DateTime.now().toIso8601String(),
    });
  }

  // Salvar item
  static Future<void> salvarItem(
    int pedidoId,
    String codigo,
    String nome,
    String quantidade,
    String unidade,
  ) async {
    final database = await db;
    await database.insert('itens', {
      'pedido_id': pedidoId,
      'codigo': codigo,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
    });
  }

  // Buscar todos os pedidos
  static Future<List<Map<String, dynamic>>> buscarPedidos() async {
    final database = await db;
    return await database.query('pedidos', orderBy: 'id DESC');
  }

  // Buscar pedidos por data
  static Future<List<Map<String, dynamic>>> buscarPedidosPorData(
    DateTime data,
  ) async {
    final database = await db;
    String dataInicio = DateTime(
      data.year,
      data.month,
      data.day,
    ).toIso8601String();
    String dataFim = DateTime(
      data.year,
      data.month,
      data.day,
      23,
      59,
      59,
    ).toIso8601String();
    return await database.query(
      'pedidos',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'id DESC',
    );
  }

  // Buscar itens de um pedido
  static Future<List<Map<String, dynamic>>> buscarItens(int pedidoId) async {
    final database = await db;
    return await database.query(
      'itens',
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
  }

  // Apagar pedido e seus itens
  static Future<void> apagarPedido(int pedidoId) async {
    final database = await db;
    await database.delete(
      'itens',
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
    await database.delete('pedidos', where: 'id = ?', whereArgs: [pedidoId]);
  }
}

