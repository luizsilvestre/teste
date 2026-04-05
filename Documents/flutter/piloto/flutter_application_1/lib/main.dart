import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'editar_pedido.dart';

void main() {
  runApp(CooperPedidos());
}

class CooperPedidos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'CooperPedidos', home: TelaPedido());
  }
}

class Produto {
  String codigo;
  String nome;
  String quantidade;
  String unidade;

  Produto(this.codigo, this.nome, this.quantidade, this.unidade);
}

class TelaPedido extends StatefulWidget {
  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
  TextEditingController codigoController = TextEditingController();
  TextEditingController nomeController = TextEditingController();
  TextEditingController quantidadeController = TextEditingController();
  TextEditingController unidadeController = TextEditingController();
  TextEditingController filialController = TextEditingController();

  List<Produto> pedido = [];
  String origemSelecionada = 'Acessório';

  void adicionarProduto() {
    if (nomeController.text.isEmpty) return;
    setState(() {
      pedido.add(
        Produto(
          codigoController.text,
          nomeController.text,
          quantidadeController.text,
          unidadeController.text,
        ),
      );
      codigoController.clear();
      nomeController.clear();
      quantidadeController.clear();
      unidadeController.clear();
    });
  }

  String get numeroFilial {
    if (origemSelecionada == 'Acessório') return '6';
    if (origemSelecionada == 'Central') return '29';
    return filialController.text;
  }

  Future<void> finalizarPedido() async {
    if (pedido.isEmpty) return;

    int pedidoId = await DatabaseHelper.salvarPedido(
      origemSelecionada,
      numeroFilial,
    );

    for (var item in pedido) {
      await DatabaseHelper.salvarItem(
        pedidoId,
        item.codigo,
        item.nome,
        item.quantidade,
        item.unidade,
      );
    }

    setState(() {
      pedido.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Pedido salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void enviarWhatsApp() async {
    if (pedido.isEmpty) return;

    String mensagem =
        '📦 *PEDIDO - $origemSelecionada (Filial $numeroFilial)*\n';
    mensagem += '━━━━━━━━━━━━━━\n';

    for (int i = 0; i < pedido.length; i++) {
      mensagem +=
          '${pedido[i].codigo} | ${pedido[i].nome} | ${pedido[i].quantidade} ${pedido[i].unidade}\n';
    }

    mensagem += '━━━━━━━━━━━━━━\n';
    mensagem += 'Total: ${pedido.length} itens';

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(mensagem)}',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CooperPedidos'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TelaHistorico()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: origemSelecionada,
                    decoration: InputDecoration(
                      labelText: 'Origem',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Acessório', 'Central', 'Outra']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (valor) {
                      setState(() {
                        origemSelecionada = valor!;
                        filialController.clear();
                      });
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: origemSelecionada == 'Outra'
                      ? TextField(
                          controller: filialController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nº da Filial',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Filial: $numeroFilial',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: codigoController,
              decoration: InputDecoration(
                labelText: 'Código do produto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do produto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: quantidadeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: unidadeController,
              decoration: InputDecoration(
                labelText: 'Unidade (kg, cx, un...)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: adicionarProduto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Adicionar Produto',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: pedido.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Text(
                        pedido[index].codigo,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      title: Text(pedido[index].nome),
                      subtitle: Text(
                        '${pedido[index].quantidade} ${pedido[index].unidade}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            pedido.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: finalizarPedido,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      '💾 Salvar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: enviarWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF25D366),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    icon: Icon(Icons.send, color: Colors.white),
                    label: Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════ TELA HISTÓRICO ═══════════════════
class TelaHistorico extends StatefulWidget {
  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  List<Map<String, dynamic>> pedidos = [];
  DateTime? dataFiltro;

  @override
  void initState() {
    super.initState();
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    List<Map<String, dynamic>> lista;
    if (dataFiltro != null) {
      lista = await DatabaseHelper.buscarPedidosPorData(dataFiltro!);
    } else {
      lista = await DatabaseHelper.buscarPedidos();
    }
    setState(() {
      pedidos = lista;
    });
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() {
        dataFiltro = data;
      });
      carregarPedidos();
    }
  }

  Future<void> apagarPedido(int id) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apagar pedido?'),
        content: Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirma == true) {
      await DatabaseHelper.apagarPedido(id);
      carregarPedidos();
    }
  }

  Future<void> abrirPedido(Map<String, dynamic> pedido) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaEditarPedido(pedido: pedido)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Pedidos'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: selecionarData,
          ),
          if (dataFiltro != null)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                setState(() {
                  dataFiltro = null;
                });
                carregarPedidos();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (dataFiltro != null)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Filtrando: ${dataFiltro!.day}/${dataFiltro!.month}/${dataFiltro!.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: pedidos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum pedido encontrado.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final p = pedidos[index];
                      final data = DateTime.parse(p['data']);
                      final dataStr =
                          '${data.day}/${data.month}/${data.year} ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.receipt, color: Colors.green),
                          title: Text('${p['origem']} — Filial ${p['filial']}'),
                          subtitle: Text(dataStr),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => abrirPedido(p),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  '📂 Abrir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => apagarPedido(p['id']),
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
    );
  }
}
