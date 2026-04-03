import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
      pedido.add(Produto(
        codigoController.text,
        nomeController.text,
        quantidadeController.text,
        unidadeController.text,
      ));
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

void enviarWhatsApp() async {
  if (pedido.isEmpty) return;

  String mensagem = '📦 *PEDIDO - $origemSelecionada (Filial $numeroFilial)*\n';
  mensagem += '━━━━━━━━━━━━━━\n';

  for (int i = 0; i < pedido.length; i++) {
    mensagem += '${pedido[i].codigo} | ${pedido[i].nome} | ${pedido[i].quantidade} ${pedido[i].unidade}\n';
  }

  mensagem += '━━━━━━━━━━━━━━\n';
  mensagem += 'Total: ${pedido.length} itens';

  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensagem)}');
  
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CooperPedidos'),
        backgroundColor: Colors.green,
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
                      subtitle: Text('${pedido[index].quantidade} ${pedido[index].unidade}'),
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