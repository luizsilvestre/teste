class Medicamento {
  final int? id;
  final String produto;
  final String lote;
  final String dataVencimento;
  final DateTime criadoEm;

  Medicamento({
    this.id,
    required this.produto,
    required this.lote,
    required this.dataVencimento,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto': produto,
      'lote': lote,
      'dataVencimento': dataVencimento,
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'],
      produto: map['produto'],
      lote: map['lote'],
      dataVencimento: map['dataVencimento'],
      criadoEm: DateTime.parse(map['criadoEm']),
    );
  }
}
