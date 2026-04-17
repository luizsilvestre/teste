import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';

class CadastroScreen extends StatefulWidget {
  final DBHelper dbHelper;
  final Function onMedicamentoAdicionado;

  const CadastroScreen({
    Key? key,
    required this.dbHelper,
    required this.onMedicamentoAdicionado,
  }) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _produtoController = TextEditingController();
  final _loteController = TextEditingController();
  DateTime? _dataVencimento;
  bool _carregando = false;

  Future<void> _selecionarData(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _dataVencimento) {
      setState(() {
        _dataVencimento = picked;
      });
    }
  }

  Future<void> _salvarMedicamento() async {
    if (_produtoController.text.isEmpty ||
        _loteController.text.isEmpty ||
        _dataVencimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final medicamento = Medicamento(
        produto: _produtoController.text,
        lote: _loteController.text,
        dataVencimento: DateFormat('dd/MM/yyyy').format(_dataVencimento!),
        criadoEm: DateTime.now(),
      );

      await widget.dbHelper.inserir(medicamento);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicamento salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpar campos
      _produtoController.clear();
      _loteController.clear();
      setState(() {
        _dataVencimento = null;
      });

      widget.onMedicamentoAdicionado();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Adicionar Medicamento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _produtoController,
            decoration: InputDecoration(
              labelText: 'Produto',
              hintText: 'Ex: Amoxicilina',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.local_pharmacy),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loteController,
            decoration: InputDecoration(
              labelText: 'Lote',
              hintText: 'Ex: 123456',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selecionarData(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    _dataVencimento == null
                        ? 'Selecione a data de vencimento'
                        : 'Data: ${DateFormat('dd/MM/yyyy').format(_dataVencimento!)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dataVencimento == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _carregando ? null : _salvarMedicamento,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade700,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _carregando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Salvar Medicamento',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _loteController.dispose();
    super.dispose();
  }
}
