class Medicamento {
  final int? id;
  final int categoriaId;
  final String produto;
  final String lote;
  final String dataVencimento;
  final DateTime criadoEm;
  final String? codigoBarras;
  final String? foto; // caminho local da foto

  Medicamento({
    this.id,
    required this.categoriaId,
    required this.produto,
    required this.lote,
    required this.dataVencimento,
    required this.criadoEm,
    this.codigoBarras,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria_id': categoriaId,
      'produto': produto,
      'lote': lote,
      'dataVencimento': dataVencimento,
      'criadoEm': criadoEm.toIso8601String(),
      'codigoBarras': codigoBarras,
      'foto': foto,
    };
  }

  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'],
      categoriaId: map['categoria_id'] ?? 1,
      produto: map['produto'],
      lote: map['lote'],
      dataVencimento: map['dataVencimento'],
      criadoEm: DateTime.parse(map['criadoEm']),
      codigoBarras: map['codigoBarras'],
      foto: map['foto'],
    );
  }
}
