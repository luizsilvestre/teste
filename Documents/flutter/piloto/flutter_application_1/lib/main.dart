import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'editar_pedido.dart';
import 'imprimir_pedido.dart';

void main() {
  runApp(CooperPedidos());
}

class CooperPedidos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CooperPedidos',
      home: TelaPedido(),
    );
  }
}

class Produto {
  String codigo;
  String nome;
  String quantidade;
  String unidade;
  String origem;
  String filial;

  Produto(this.codigo, this.nome, this.quantidade, this.unidade, this.origem, this.filial);
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
  TextEditingController filialIndustriaController = TextEditingController();

  List<Produto> pedido = [];
  String origemSelecionada = 'Central';

  String get numeroFilial {
    if (origemSelecionada == 'Central') return '29';
    if (origemSelecionada == 'Acessórios') return '6';
    return filialIndustriaController.text;
  }

  void adicionarProduto() {
    if (nomeController.text.isEmpty) return;
    if (origemSelecionada == 'Indústria' && filialIndustriaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Informe o número da filial da Indústria!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      pedido.add(Produto(
        codigoController.text,
        nomeController.text,
        quantidadeController.text,
        unidadeController.text,
        origemSelecionada,
        numeroFilial,
      ));
      codigoController.clear();
      nomeController.clear();
      quantidadeController.clear();
      unidadeController.clear();
    });
  }

  Future<void> finalizarPedido() async {
    if (pedido.isEmpty) return;

    final origens = pedido.map((p) => '${p.origem}|${p.filial}').toSet();

    for (var origemFilial in origens) {
      final partes = origemFilial.split('|');
      final origem = partes[0];
      final filial = partes[1];

      int pedidoId = await DatabaseHelper.salvarPedido(origem, filial);

      final itensDaOrigem = pedido
          .where((p) => p.origem == origem && p.filial == filial)
          .toList();

      for (var item in itensDaOrigem) {
        await DatabaseHelper.salvarItem(
          pedidoId,
          item.codigo,
          item.nome,
          item.quantidade,
          item.unidade,
          origem: item.origem,
          filial: item.filial,
        );
      }
    }

    setState(() { pedido.clear(); });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Pedido salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void enviarWhatsApp() async {
    if (pedido.isEmpty) return;

    final central = pedido.where((p) => p.origem == 'Central').toList();
    final acessorios = pedido.where((p) => p.origem == 'Acessórios').toList();
    final industria = pedido.where((p) => p.origem == 'Indústria').toList();

    String mensagem = '';

    if (central.isNotEmpty) {
      mensagem += '📦 *CENTRAL DE DISTRIBUIÇÃO — Filial 29*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in central) {
        mensagem += '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${central.length} itens\n\n';
    }

    if (acessorios.isNotEmpty) {
      mensagem += '📦 *ACESSÓRIOS — Filial 6*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in acessorios) {
        mensagem += '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${acessorios.length} itens\n\n';
    }

    if (industria.isNotEmpty) {
      mensagem += '📦 *INDÚSTRIA — Filial ${industria.first.filial}*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in industria) {
        mensagem += '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${industria.length} itens\n';
    }

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(mensagem)}'
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final central = pedido.where((p) => p.origem == 'Central').toList();
    final acessorios = pedido.where((p) => p.origem == 'Acessórios').toList();
    final industria = pedido.where((p) => p.origem == 'Indústria').toList();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 40),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: pedido.isEmpty ? null : enviarWhatsApp,
          ),
          IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: pedido.isEmpty ? null : () {
              ImprimirPedido.imprimir(context, pedido);
            },
          ),
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
            DropdownButtonFormField<String>(
              value: origemSelecionada,
              decoration: InputDecoration(
                labelText: 'Origem',
                border: OutlineInputBorder(),
              ),
              items: ['Central', 'Acessórios', 'Indústria']
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  origemSelecionada = valor!;
                  filialIndustriaController.clear();
                });
              },
            ),
            if (origemSelecionada == 'Indústria') ...[
              SizedBox(height: 8),
              TextField(
                controller: filialIndustriaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nº da Filial da Indústria',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Filial: $numeroFilial', style: TextStyle(fontSize: 16)),
              ),
            ],
            SizedBox(height: 12),
            TextField(
              controller: codigoController,
              decoration: InputDecoration(
                labelText: 'Código',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do produto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: unidadeController,
                    decoration: InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: adicionarProduto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('✚ Adicionar Produto', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 8),
            Expanded(
              child: pedido.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum produto adicionado.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: [
                        if (central.isNotEmpty) _secao('Central de Distribuição', '29', central, Colors.blue),
                        if (acessorios.isNotEmpty) _secao('Acessórios', '6', acessorios, Colors.orange),
                        if (industria.isNotEmpty) _secao('Indústria', industria.first.filial, industria, Colors.purple),
                      ],
                    ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: finalizarPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('💾 Salvar Pedido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, String filial, List<Produto> itens, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.15),
            border: Border.all(color: cor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$titulo — Filial $filial (${itens.length} itens)',
            style: TextStyle(fontWeight: FontWeight.bold, color: cor),
          ),
        ),
        ...itens.map((item) => Card(
          child: ListTile(
            leading: Text(item.codigo, style: TextStyle(fontWeight: FontWeight.bold)),
            title: Text(item.nome),
            subtitle: Text('${item.quantidade} ${item.unidade}'),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() { pedido.remove(item); });
              },
            ),
          ),
        )),
        SizedBox(height: 8),
      ],
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
    setState(() { pedidos = lista; });
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() { dataFiltro = data; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico'),
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
                setState(() { dataFiltro = null; });
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TelaEditarPedido(pedido: p),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  '📂 Abrir',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
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
