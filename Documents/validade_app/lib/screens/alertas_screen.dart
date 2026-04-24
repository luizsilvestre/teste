import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/db_helper.dart';
import '../models/medicamento.dart';

class AlertasScreen extends StatefulWidget {
  final DBHelper dbHelper;

  const AlertasScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final _numeroController = TextEditingController();
  List<Medicamento> _medicamentosVencimento = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarMedicamentosVencimento();
  }

  Future<void> _carregarMedicamentosVencimento() async {
    final medicamentos = await widget.dbHelper.buscarTodos();
    
    final agora = DateTime.now();
    final emTresMeses = agora.add(const Duration(days: 90));

    final vencendo = medicamentos.where((med) {
      try {
        final partes = med.dataVencimento.split('/');
        final data = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
        return data.isAfter(agora) && data.isBefore(emTresMeses);
      } catch (e) {
        return false;
      }
    }).toList();

    setState(() {
      _medicamentosVencimento = vencendo;
    });
  }

  Future<void> _enviarAlerta(Medicamento medicamento) async {
    if (_numeroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o número do WhatsApp!')),
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/alertar-vencimento'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numero': _numeroController.text,
          'medicamento': medicamento.produto,
          'dataVencimento': medicamento.dataVencimento,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alerta enviado via WhatsApp!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erro ao enviar alerta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro: $e')),
      );
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
            'Alertas de Vencimento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _numeroController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Número WhatsApp (ex: 11999999999)',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Medicamentos vencendo em 3 meses:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _medicamentosVencimento.isEmpty
                ? const Center(
                    child: Text('Nenhum medicamento vencendo em breve! ✅'),
                  )
                : ListView.builder(
                    itemCount: _medicamentosVencimento.length,
                    itemBuilder: (context, index) {
                      final med = _medicamentosVencimento[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(med.produto),
                          subtitle: Text('Vence: ${med.dataVencimento}'),
                          trailing: ElevatedButton(
                            onPressed: _carregando
                                ? null
                                : () => _enviarAlerta(med),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Alertar'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }
}
