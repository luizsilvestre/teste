import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class CategoriasScreen extends StatefulWidget {
  final DBHelper dbHelper;

  const CategoriasScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<Map<String, dynamic>> _categorias = [];
  final _nomeController = TextEditingController();
  String _corSelecionada = '#FF5252';

  final List<String> _cores = [
    '#FF5252', // Vermelho
    '#FFA726', // Laranja
    '#66BB6A', // Verde
    '#29B6F6', // Azul
    '#AB47BC', // Roxo
    '#EC407A', // Rosa
    '#FFEE58', // Amarelo
    '#26A69A', // Teal
  ];

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final categorias = await widget.dbHelper.buscarCategorias();
    setState(() {
      _categorias = categorias;
    });
  }

  void _mostrarDialogoNovaCategoria() {
    _nomeController.clear();
    _corSelecionada = '#FF5252';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da categoria',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Selecione uma cor:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _cores.map((cor) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _corSelecionada = cor;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse(cor.replaceFirst('#', '0xff'))),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _corSelecionada == cor ? Colors.black : Colors.grey,
                        width: _corSelecionada == cor ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_nomeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Digite um nome!')),
                );
                return;
              }

              await widget.dbHelper.inserirCategoria(
                _nomeController.text,
                _corSelecionada,
              );

              Navigator.pop(context);
              _carregarCategorias();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Categoria adicionada!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _mostrarDialogoNovaCategoria,
              icon: const Icon(Icons.add),
              label: const Text('Nova Categoria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _categorias.isEmpty
                  ? const Center(
                      child: Text('Nenhuma categoria encontrada'),
                    )
                  : ListView.builder(
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = _categorias[index];
                        final cor = Color(int.parse(
                          categoria['cor'].replaceFirst('#', '0xff'),
                        ));

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            title: Text(categoria['nome']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await widget.dbHelper.deletarCategoria(categoria['id']);
                                _carregarCategorias();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Categoria deletada!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }
}
