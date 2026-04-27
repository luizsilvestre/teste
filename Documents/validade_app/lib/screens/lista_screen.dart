import 'dart:io';
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
  int? _categoriaSelecionada;

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

  // Busca categorias do banco para exibir nome e cor
  Future<void> _carregarCategorias() async {
    final cats = await widget.dbHelper.buscarCategorias();
    setState(() => _categorias = cats);
  }

  // Ordena pelo vencimento mais próximo primeiro
  void _ordenarPorValidade() {
    _medicamentos.sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a.dataVencimento);
      final dateB = DateFormat('dd/MM/yyyy').parse(b.dataVencimento);
      return dateA.compareTo(dateB);
    });
  }

  // Agrupa produtos pelo nome — mesmo produto, lotes diferentes
  Map<String, List<Medicamento>> _agrupar(List<Medicamento> lista) {
    final Map<String, List<Medicamento>> grupos = {};
    for (final med in lista) {
      grupos.putIfAbsent(med.produto, () => []);
      grupos[med.produto]!.add(med);
    }
    return grupos;
  }

  // Filtra por categoria selecionada (null = todos)
  List<Medicamento> get _filtrados {
    if (_categoriaSelecionada == null) return _medicamentos;
    return _medicamentos
        .where((m) => m.categoriaId == _categoriaSelecionada)
        .toList();
  }

  // Calcula dias restantes até o vencimento (negativo = vencido)
  int _dias(String dataVencimento) {
    final vencimento = DateFormat('dd/MM/yyyy').parse(dataVencimento);
    return vencimento.difference(DateTime.now()).inDays;
  }

  // Retorna cor baseada na urgência
  Color _cor(int dias) {
    if (dias < 0) return Colors.red;
    if (dias <= 30) return Colors.orange;
    if (dias <= 90) return Colors.yellow.shade700;
    return Colors.green;
  }

  // Retorna texto de status baseado na urgência
  String _status(int dias) {
    if (dias < 0) return 'VENCIDO';
    if (dias == 0) return 'VENCE HOJE';
    if (dias <= 30) return 'URGENTE';
    if (dias <= 90) return 'ATENÇÃO';
    return 'OK';
  }

  // Busca nome da categoria pelo id
  String _nomeCategoria(int id) {
    final cat = _categorias.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'nome': ''},
    );
    return cat['nome'] as String;
  }

  // ===== DELETAR PRODUTO =====
  Future<void> _deletar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
    if (ok == true) {
      await widget.dbHelper.deletar(id);
      widget.onMedicamentoDeletado();
    }
  }

  // ===== EDITAR PRODUTO =====
  // Abre bottom sheet com campos preenchidos para edição
  void _editarMedicamento(Medicamento med) {
    final produtoController = TextEditingController(text: med.produto);
    final loteController = TextEditingController(text: med.lote);
    DateTime? dataVencimento =
        DateFormat('dd/MM/yyyy').parse(med.dataVencimento);
    int? categoriaSelecionada = med.categoriaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // evita tela branca ao abrir teclado
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          // Padding dinâmico sobe o sheet quando o teclado aparece
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle visual do bottom sheet
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Editar Produto',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown de categoria
                  DropdownButtonFormField<int>(
                    value: categoriaSelecionada,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _categorias.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'] as int,
                        child: Text(cat['nome'] as String),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setSheetState(() => categoriaSelecionada = v),
                  ),
                  const SizedBox(height: 12),

                  // Campo nome do produto
                  TextField(
                    controller: produtoController,
                    decoration: InputDecoration(
                      labelText: 'Nome do produto',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.local_pharmacy),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Campo lote
                  TextField(
                    controller: loteController,
                    decoration: InputDecoration(
                      labelText: 'Lote',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seletor de data de vencimento
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dataVencimento ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setSheetState(() => dataVencimento = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            dataVencimento == null
                                ? 'Data de vencimento'
                                : DateFormat('dd/MM/yyyy')
                                    .format(dataVencimento!),
                            style: TextStyle(
                              fontSize: 15,
                              color: dataVencimento == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botão salvar alterações
                  ElevatedButton(
                    onPressed: () async {
                      if (produtoController.text.isEmpty ||
                          loteController.text.isEmpty ||
                          dataVencimento == null ||
                          categoriaSelecionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Preencha todos os campos!')),
                        );
                        return;
                      }

                      // Mantém foto e código de barras originais
                      final atualizado = Medicamento(
                        id: med.id,
                        categoriaId: categoriaSelecionada!,
                        produto: produtoController.text,
                        lote: loteController.text,
                        dataVencimento: DateFormat('dd/MM/yyyy')
                            .format(dataVencimento!),
                        criadoEm: med.criadoEm,
                        codigoBarras: med.codigoBarras,
                        foto: med.foto,
                      );

                      // Atualiza no banco de dados
                      final db = await widget.dbHelper.database;
                      await db.update(
                        'medicamentos',
                        atualizado.toMap(),
                        where: 'id = ?',
                        whereArgs: [med.id],
                      );

                      if (context.mounted) Navigator.pop(context);
                      widget.onMedicamentoDeletado(); // recarrega a lista

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Produto atualizado!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Salvar Alterações',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    final grupos = _agrupar(lista);
    final nomes = grupos.keys.toList();

    return Column(
      children: [
        // ===== CHIPS DE FILTRO POR CATEGORIA =====
        if (_categorias.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _chip('Todos', null),
                ..._categorias
                    .map((c) => _chip(c['nome'] as String, c['id'] as int)),
              ],
            ),
          ),

        // ===== LISTA AGRUPADA POR PRODUTO =====
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum produto cadastrado',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: nomes.length,
                  itemBuilder: (context, index) {
                    final nome = nomes[index];
                    final lotes = grupos[nome]!;

                    // Status mais crítico do grupo (menor dias = mais urgente)
                    final diasCritico = lotes
                        .map((m) => _dias(m.dataVencimento))
                        .reduce((a, b) => a < b ? a : b);
                    final corCritica = _cor(diasCritico);
                    final statusCritico = _status(diasCritico);

                    // Usa foto do primeiro lote que tiver
                    final foto = lotes
                        .firstWhere((m) => m.foto != null,
                            orElse: () => lotes.first)
                        .foto;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: corCritica, width: 2),
                      ),
                      child: Column(
                        children: [
                          // ===== HEADER DO GRUPO =====
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Foto do produto
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: foto != null
                                      ? Image.file(
                                          File(foto),
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.local_pharmacy,
                                              color: Colors.grey.shade400),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Nome do produto
                                      Text(
                                        nome,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Categoria
                                      Text(
                                        _nomeCategoria(
                                            lotes.first.categoriaId),
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12),
                                      ),
                                      // Código de barras (se houver)
                                      if (lotes.first.codigoBarras != null)
                                        Text(
                                          lotes.first.codigoBarras!,
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                // Badge do status mais crítico
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: corCritica,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusCritico,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ===== LOTES DO PRODUTO =====
                          const Divider(height: 1),
                          ...lotes.map((med) {
                            final dias = _dias(med.dataVencimento);
                            final cor = _cor(dias);

                            return Container(
                              decoration: BoxDecoration(
                                color: cor.withOpacity(0.05),
                                // Arredonda o último lote embaixo
                                borderRadius: lotes.last == med
                                    ? const BorderRadius.vertical(
                                        bottom: Radius.circular(12))
                                    : null,
                              ),
                              child: ListTile(
                                dense: true,
                                // Bolinha colorida indicando urgência
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: cor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  'Lote: ${med.lote}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${med.dataVencimento}  •  '
                                  '${dias < 0 ? "Vencido há ${dias.abs()} dias" : "$dias dias restantes"}',
                                  style: TextStyle(
                                    color: cor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botão editar lote
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.blue, size: 20),
                                      onPressed: () =>
                                          _editarMedicamento(med),
                                    ),
                                    // Botão deletar lote
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20),
                                      onPressed: () => _deletar(med.id!),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===== CHIP DE FILTRO =====
  Widget _chip(String label, int? id) {
    final sel = _categoriaSelecionada == id;
    return GestureDetector(
      onTap: () => setState(() => _categoriaSelecionada = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? Colors.blue.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
