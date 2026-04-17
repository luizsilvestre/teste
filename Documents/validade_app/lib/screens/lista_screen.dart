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

  @override
  void initState() {
    super.initState();
    _medicamentos = widget.medicamentos;
    _ordenarPorValidade();
  }

  @override
  void didUpdateWidget(ListaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _medicamentos = widget.medicamentos;
    _ordenarPorValidade();
  }

  void _ordenarPorValidade() {
    _medicamentos.sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a.dataVencimento);
      final dateB = DateFormat('dd/MM/yyyy').parse(b.dataVencimento);
      return dateA.compareTo(dateB);
    });
  }

  int _calcularDiasRestantes(String dataVencimento) {
    final hoje = DateTime.now();
    final vencimento = DateFormat('dd/MM/yyyy').parse(dataVencimento);
    final diferenca = vencimento.difference(hoje).inDays;
    return diferenca;
  }

  Color _obterCor(int diasRestantes) {
    if (diasRestantes < 0) {
      return Colors.red;
    } else if (diasRestantes <= 30) {
      return Colors.orange;
    } else if (diasRestantes <= 90) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  String _obterStatus(int diasRestantes) {
    if (diasRestantes < 0) {
      return 'VENCIDO';
    } else if (diasRestantes == 0) {
      return 'VENCE HOJE';
    } else if (diasRestantes <= 30) {
      return 'URGENTE';
    } else if (diasRestantes <= 90) {
      return 'ATENÇÃO';
    } else {
      return 'OK';
    }
  }

  Future<void> _deletarMedicamento(int id) async {
    final confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Medicamento?'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medicamento deletado!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_medicamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Nenhum medicamento cadastrado',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medicamentos.length,
      itemBuilder: (context, index) {
        final med = _medicamentos[index];
        final diasRestantes = _calcularDiasRestantes(med.dataVencimento);
        final cor = _obterCor(diasRestantes);
        final status = _obterStatus(diasRestantes);

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.produto,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lote: ${med.lote}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vence em: ${med.dataVencimento}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dias restantes: $diasRestantes',
                            style: TextStyle(
                              fontSize: 14,
                              color: cor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _deletarMedicamento(med.id!),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
