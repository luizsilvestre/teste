import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'main.dart' show Produto;
import 'imprimir_pedido.dart';

class TelaEditarPedido extends StatefulWidget {
  final Map<String, dynamic> pedido;

  const TelaEditarPedido({Key? key, required this.pedido}) : super(key: key);

  @override
  State<TelaEditarPedido> createState() => _TelaEditarPedidoState();
}

class _TelaEditarPedidoState extends State<TelaEditarPedido> {
  TextEditingController codigoController = TextEditingController();
  TextEditingController nomeController = TextEditingController();
  TextEditingController quantidadeController = TextEditingController();
  TextEditingController unidadeController = TextEditingController();
  TextEditingController filialIndustriaController = TextEditingController();

  List<Produto> itens = [];
  bool carregando = true;
  String origemSelecionada = 'Central';

  @override
  void initState() {
    super.initState();
    origemSelecionada = widget.pedido['origem'] ?? 'Central';
    carregarItens();
  }

  Future<void> carregarItens() async {
    final lista = await DatabaseHelper.buscarItens(widget.pedido['id']);
    setState(() {
      itens = lista
          .map(
            (i) => Produto(
              i['codigo'] ?? '',
              i['nome'] ?? '',
              i['quantidade'] ?? '',
              i['unidade'] ?? '',
              i['origem'] ?? widget.pedido['origem'] ?? '',
              i['filial'] ?? widget.pedido['filial'] ?? '',
            ),
          )
          .toList();
      carregando = false;
    });
  }

  String get numeroFilial {
    if (origemSelecionada == 'Central') return '29';
    if (origemSelecionada == 'Acessórios') return '6';
    return filialIndustriaController.text;
  }

  void adicionarProduto() {
    if (nomeController.text.isEmpty) return;
    setState(() {
      itens.add(
        Produto(
          codigoController.text,
          nomeController.text,
          quantidadeController.text,
          unidadeController.text,
          origemSelecionada,
          numeroFilial,
        ),
      );
      codigoController.clear();
      nomeController.clear();
      quantidadeController.clear();
      unidadeController.clear();
    });
  }

  void removerItem(int index) {
    setState(() {
      itens.removeAt(index);
    });
  }

  void enviarWhatsApp() async {
    if (itens.isEmpty) return;

    final central = itens.where((p) => p.origem == 'Central').toList();
    final acessorios = itens.where((p) => p.origem == 'Acessórios').toList();
    final industria = itens.where((p) => p.origem == 'Indústria').toList();

    String mensagem = '';

    if (central.isNotEmpty) {
      mensagem += '📦 *CENTRAL DE DISTRIBUIÇÃO — Filial 29*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in central) {
        mensagem +=
            '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${central.length} itens\n\n';
    }

    if (acessorios.isNotEmpty) {
      mensagem += '📦 *ACESSÓRIOS — Filial 6*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in acessorios) {
        mensagem +=
            '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${acessorios.length} itens\n\n';
    }

    if (industria.isNotEmpty) {
      mensagem += '📦 *INDÚSTRIA — Filial ${industria.first.filial}*\n';
      mensagem += '━━━━━━━━━━━━━━\n';
      for (var item in industria) {
        mensagem +=
            '${item.codigo} | ${item.nome} | ${item.quantidade} ${item.unidade}\n';
      }
      mensagem += 'Total: ${industria.length} itens\n';
    }

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(mensagem)}',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final central = itens.where((p) => p.origem == 'Central').toList();
    final acessorios = itens.where((p) => p.origem == 'Acessórios').toList();
    final industria = itens.where((p) => p.origem == 'Indústria').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Pedido'),
        backgroundColor: Colors.green,
      ),
      body: carregando
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Origem
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
                      child: Text(
                        'Filial: $numeroFilial',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
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
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: Text(
                      '✚ Adicionar Produto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        if (central.isNotEmpty)
                          _secao('Central', '29', central, Colors.blue),
                        if (acessorios.isNotEmpty)
                          _secao('Acessórios', '6', acessorios, Colors.orange),
                        if (industria.isNotEmpty)
                          _secao(
                            'Indústria',
                            industria.first.filial,
                            industria,
                            Colors.purple,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
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
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              ImprimirPedido.imprimir(context, itens),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          icon: Icon(Icons.print, color: Colors.white),
                          label: Text(
                            'Imprimir',
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
        ...itens.map(
          (item) => Card(
            child: ListTile(
              leading: Text(
                item.codigo,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(item.nome),
              subtitle: Text('${item.quantidade} ${item.unidade}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() {
                  itens.remove(item);
                }),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
