import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart' show Produto;

class ImprimirPedido {
  static Future<void> imprimir(
    BuildContext context,
    List<Produto> todosItens,
  ) async {
    final pdf = pw.Document();

    // Separar por origem
    final central = todosItens.where((p) => p.origem == 'Central').toList();
    final acessorios = todosItens.where((p) => p.origem == 'Acessórios').toList();
    final industria = todosItens.where((p) => p.origem == 'Indústria').toList();

    // Gerar uma página para cada origem que tiver itens
    if (central.isNotEmpty) {
      pdf.addPage(_gerarPagina('Central de Distribuição', '29', central));
    }
    if (acessorios.isNotEmpty) {
      pdf.addPage(_gerarPagina('Acessórios', '6', acessorios));
    }
    if (industria.isNotEmpty) {
      pdf.addPage(_gerarPagina('Indústria', industria.first.filial, industria));
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Page _gerarPagina(String origem, String filial, List<Produto> itens) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'COOPERSULCA',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '$origem — Filial $filial',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Data: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabela
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: pw.FixedColumnWidth(80),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(80),
                3: pw.FixedColumnWidth(60),
              },
              children: [
                // Cabeçalho da tabela
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _celula('CÓDIGO', bold: true),
                    _celula('PRODUTO', bold: true),
                    _celula('QUANTIDADE', bold: true),
                    _celula('UNID.', bold: true),
                  ],
                ),
                // Itens
                ...itens.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                    ),
                    children: [
                      _celula(item.codigo),
                      _celula(item.nome),
                      _celula(item.quantidade),
                      _celula(item.unidade),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Rodapé
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total: ${itens.length} itens',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Assinatura: ___________________________',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static pw.Widget _celula(String texto, {bool bold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}