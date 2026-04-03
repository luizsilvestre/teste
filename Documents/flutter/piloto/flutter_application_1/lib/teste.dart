class Produto {
  String nome;
  int quantidade;
  String unidade;

  Produto(this.nome, this.quantidade, this.unidade);
}

void main() {
  List<Produto> pedido = [
    Produto('Frango', 10, 'kg'),
    Produto('Arroz', 50, 'kg'),
    Produto('Feijão', 30, 'kg'),
  ];

  for (int i = 0; i < pedido.length; i++) {
    print('O produto ${pedido[i].nome} tem a quantidade de ${pedido[i].quantidade} ${pedido[i].unidade}.');
  }
}