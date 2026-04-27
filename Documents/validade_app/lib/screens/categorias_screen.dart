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

  // Cores disponíveis para categoria
  final List<String> _cores = [
    '#FF5252', '#FFA726', '#66BB6A', '#29B6F6',
    '#AB47BC', '#EC407A', '#FFEE58', '#26A69A',
  ];

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    final categorias = await widget.dbHelper.buscarCategorias();
    setState(() => _categorias = categorias);
  }

  Color _hexParaColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xff')));

  // ===== DIALOG NOVA/EDITAR CATEGORIA =====
  // Usa StatefulBuilder para que a seleção de cor funcione dentro do dialog
  void _mostrarDialogo({Map<String, dynamic>? categoriaExistente}) {
    _nomeController.text = categoriaExistente?['nome'] ?? '';
    String corSelecionada = categoriaExistente?['cor'] ?? '#FF5252';
    final editando = categoriaExistente != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // StatefulBuilder permite setState local dentro do dialog
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editando ? 'Editar Categoria' : 'Nova Categoria'),
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
                runSpacing: 8,
                children: _cores.map((cor) {
                  final selecionada = corSelecionada == cor;
                  return GestureDetector(
                    onTap: () {
                      // setDialogState atualiza apenas o dialog
                      setDialogState(() => corSelecionada = cor);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _hexParaColor(cor),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selecionada ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selecionada
                            ? [BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                              )]
                            : [],
                      ),
                      child: selecionada
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
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

                if (editando) {
                  // Atualiza categoria existente
                  await widget.dbHelper.atualizarCategoria(
                    categoriaExistente['id'],
                    _nomeController.text,
                    corSelecionada,
                  );
                } else {
                  // Insere nova categoria
                  await widget.dbHelper.inserirCategoria(
                    _nomeController.text,
                    corSelecionada,
                  );
                }

                if (context.mounted) Navigator.pop(context);
                _carregarCategorias();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editando
                          ? '✅ Categoria atualizada!'
                          : '✅ Categoria adicionada!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(editando ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão nova categoria
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogo(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nova Categoria',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de categorias
            Expanded(
              child: _categorias.isEmpty
                  ? const Center(child: Text('Nenhuma categoria encontrada'))
                  : ListView.builder(
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        final cat = _categorias[index];
                        final cor = _hexParaColor(cat['cor']);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            title: Text(cat['nome'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botão editar
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      _mostrarDialogo(categoriaExistente: cat),
                                ),
                                // Botão deletar
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await widget.dbHelper
                                        .deletarCategoria(cat['id']);
                                    _carregarCategorias();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('✅ Categoria deletada!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
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
