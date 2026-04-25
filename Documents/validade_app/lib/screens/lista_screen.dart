import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';

class ListaScreen extends StatefulWidget {
  final List<Medicamento> medicamentos;
  final DBHelper dbHelper;
  final Function onMedicamentoDeletado;

  const ListaScreen({
    Key? key,
    required this.medicamentos,
    required this.dbHelper,
    required this.onMedicamentoDeletado,
  }) : super(key: key);

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  late List<Medicamento> _medicamentos;
  List<Map<String, dynamic>> _categorias = [];
  int? _categoriaSelecionada; // null = todas

  @override
  void initState() {
    super.initState();
    _medicamentos = widget.medicamentos;
    _ordenarPorValidade();
    _carregarCategorias();
  }

  @override
  void didUpdateWidget(ListaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _medicamentos = widget.medicamentos;
    _ordenarPorValidade();
  }

  Future<void> _carregarCategorias() async {
    final cats = await widget.dbHelper.buscarCategorias();
    setState(() {
      _categorias = cats;
    });
  }

  void _ordenarPorValidade() {
    _medicamentos.sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a.dataVencimento);
      final dateB = DateFormat('dd/MM/yyyy').parse(b.dataVencimento);
      return dateA.compareTo(dateB);
    });
  }

  List<Medicamento> get _medicamentosFiltrados {
    if (_categoriaSelecionada == null) return _medicamentos;
    return _medicamentos
        .where((m) => m.categoriaId == _categoriaSelecionada)
        .toList();
  }

  int _calcularDiasRestantes(String dataVencimento) {
    final hoje = DateTime.now();
    final vencimento = DateFormat('dd/MM/yyyy').parse(dataVencimento);
    return vencimento.difference(hoje).inDays;
  }

  Color _obterCor(int diasRestantes) {
    if (diasRestantes < 0) return Colors.red;
    if (diasRestantes <= 30) return Colors.orange;
    if (diasRestantes <= 90) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _obterStatus(int diasRestantes) {
    if (diasRestantes < 0) return 'VENCIDO';
    if (diasRestantes == 0) return 'VENCE HOJE';
    if (diasRestantes <= 30) return 'URGENTE';
    if (diasRestantes <= 90) return 'ATENÇÃO';
    return 'OK';
  }

  String _nomeCategoria(int categoriaId) {
    final cat = _categorias.firstWhere(
      (c) => c['id'] == categoriaId,
      orElse: () => {'nome': 'Sem categoria'},
    );
    return cat['nome'] as String;
  }

  Color _corCategoria(int categoriaId) {
    final cat = _categorias.firstWhere(
      (c) => c['id'] == categoriaId,
      orElse: () => {'cor': '#9E9E9E'},
    );
    try {
      final hex = (cat['cor'] as String).replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _deletarMedicamento(int id) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar produto?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await widget.dbHelper.deletar(id);
      widget.onMedicamentoDeletado();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto deletado!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _medicamentosFiltrados;

    return Column(
      children: [
        // Filtro por categoria
        if (_categorias.isNotEmpty)
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chipFiltro('Todos', null),
                ..._categorias.map((cat) => _chipFiltro(
                      cat['nome'] as String,
                      cat['id'] as int,
                      cor: (() {
                        try {
                          final hex =
                              (cat['cor'] as String).replaceAll('#', '');
                          return Color(int.parse('FF$hex', radix: 16));
                        } catch (_) {
                          return Colors.grey;
                        }
                      })(),
                    )),
              ],
            ),
          ),

        // Lista
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text(
                        'Nenhum produto cadastrado',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final med = lista[index];
                    final dias = _calcularDiasRestantes(med.dataVencimento);
                    final cor = _obterCor(dias);
                    final status = _obterStatus(dias);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cor, width: 3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.produto,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(
                                                  right: 6),
                                              decoration: BoxDecoration(
                                                color: _corCategoria(
                                                    med.categoriaId),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Text(
                                              _nomeCategoria(med.categoriaId),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lote: ${med.lote}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vence em: ${med.dataVencimento}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dias < 0
                                            ? 'Vencido há ${dias.abs()} dias'
                                            : 'Dias restantes: $dias',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: cor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _deletarMedicamento(med.id!),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chipFiltro(String label, int? categoriaId, {Color? cor}) {
    final selecionado = _categoriaSelecionada == categoriaId;
    return GestureDetector(
      onTap: () => setState(() => _categoriaSelecionada = categoriaId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? (cor ?? Colors.blue.shade700) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
