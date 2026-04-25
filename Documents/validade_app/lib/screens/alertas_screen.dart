import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<Medicamento> _vencidos = [];
  List<Medicamento> _urgentes = [];
  List<Medicamento> _atencao = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    setState(() => _carregando = true);
    final todos = await widget.dbHelper.buscarTodos();
    final agora = DateTime.now();

    List<Medicamento> vencidos = [];
    List<Medicamento> urgentes = [];
    List<Medicamento> atencao = [];

    for (final med in todos) {
      try {
        final partes = med.dataVencimento.split('/');
        final data = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
        final dias = data.difference(agora).inDays;

        if (dias < 0) {
          vencidos.add(med);
        } else if (dias <= 30) {
          urgentes.add(med);
        } else if (dias <= 90) {
          atencao.add(med);
        }
      } catch (_) {}
    }

    setState(() {
      _vencidos = vencidos;
      _urgentes = urgentes;
      _atencao = atencao;
      _carregando = false;
    });
  }

  Future<void> _enviarWhatsApp(Medicamento med) async {
    final numero = _numeroController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o número do WhatsApp!')),
      );
      return;
    }

    final partes = med.dataVencimento.split('/');
    final data = DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
    final dias = data.difference(DateTime.now()).inDays;

    String mensagem;
    if (dias < 0) {
      mensagem =
          '⚠️ *PRODUTO VENCIDO*\n\nProduto: ${med.produto}\nLote: ${med.lote}\nVencimento: ${med.dataVencimento}\n\nEste produto está vencido há ${dias.abs()} dias!';
    } else {
      mensagem =
          '⚠️ *ALERTA DE VENCIMENTO*\n\nProduto: ${med.produto}\nLote: ${med.lote}\nVencimento: ${med.dataVencimento}\n\nRestam apenas $dias dias para o vencimento!';
    }

    final url = Uri.parse(
      'https://wa.me/55$numero?text=${Uri.encodeComponent(mensagem)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _vencidos.length + _urgentes.length + _atencao.length;

    return _carregando
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _carregarMedicamentos,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Alertas de Vencimento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // Campo WhatsApp
                TextField(
                  controller: _numeroController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp para alertar (ex: 48999999999)',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resumo
                Row(
                  children: [
                    _resumoCard('Vencidos', _vencidos.length, Colors.red),
                    const SizedBox(width: 8),
                    _resumoCard('Urgentes', _urgentes.length, Colors.orange),
                    const SizedBox(width: 8),
                    _resumoCard('Atenção', _atencao.length, Colors.yellow.shade700),
                  ],
                ),
                const SizedBox(height: 20),

                if (total == 0)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.check_circle,
                            size: 80, color: Colors.green.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Tudo em dia! ✅',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                            'Nenhum produto vencido ou vencendo em breve.'),
                      ],
                    ),
                  ),

                if (_vencidos.isNotEmpty) ...[
                  _secaoTitulo('🔴 Vencidos', Colors.red),
                  ..._vencidos.map((m) => _cardAlerta(m, Colors.red)),
                ],
                if (_urgentes.isNotEmpty) ...[
                  _secaoTitulo('🟠 Urgente (até 30 dias)', Colors.orange),
                  ..._urgentes.map((m) => _cardAlerta(m, Colors.orange)),
                ],
                if (_atencao.isNotEmpty) ...[
                  _secaoTitulo('🟡 Atenção (31–90 dias)', Colors.yellow.shade700),
                  ..._atencao.map((m) => _cardAlerta(m, Colors.yellow.shade700)),
                ],
              ],
            ),
          );
  }

  Widget _resumoCard(String label, int count, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: cor),
            ),
            Text(label,
                style: TextStyle(fontSize: 12, color: cor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String titulo, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        titulo,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }

  Widget _cardAlerta(Medicamento med, Color cor) {
    final partes = med.dataVencimento.split('/');
    final data = DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
    final dias = data.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: cor),
        title: Text(med.produto,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Lote: ${med.lote} • Vence: ${med.dataVencimento}\n'
          '${dias < 0 ? "Vencido há ${dias.abs()} dias" : "Restam $dias dias"}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.send, color: Colors.green),
          tooltip: 'Alertar via WhatsApp',
          onPressed: () => _enviarWhatsApp(med),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }
}
