import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database.dart';
import 'main.dart' show Produto;

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

  List<Produto> itens = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
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
            ),
          )
          .toList();
      carregando = false;
    });
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

    String origem = widget.pedido['origem'] ?? '';
    String filial = widget.pedido['filial'] ?? '';

    String mensagem = '📦 *PEDIDO - $origem (Filial $filial)*\n';
    mensagem += '━━━━━━━━━━━━━━\n';

    for (int i = 0; i < itens.length; i++) {
      mensagem +=
          '${itens[i].codigo} | ${itens[i].nome} | ${itens[i].quantidade} ${itens[i].unidade}\n';
    }

    mensagem += '━━━━━━━━━━━━━━\n';
    mensagem += 'Total: ${itens.length} itens';

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(mensagem)}',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '${widget.pedido['origem']} — Filial ${widget.pedido['filial']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: Text(
                      '✚ Adicionar Produto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: itens.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: Text(
                              itens[index].codigo,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            title: Text(itens[index].nome),
                            subtitle: Text(
                              '${itens[index].quantidade} ${itens[index].unidade}',
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removerItem(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: enviarWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF25D366),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    icon: Icon(Icons.send, color: Colors.white),
                    label: Text(
                      'Enviar pelo WhatsApp',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
