import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../domain/stock_counts.dart';

class StockCountPdfService {
  static const List<XTypeGroup> _pdfTypeGroups = [
    XTypeGroup(label: 'Documento PDF', extensions: ['pdf']),
  ];

  Future<String?> exportWorksheet(StockCountDetails details) async {
    final selectedLines = details.lines
        .where((line) => line.selectedForExport)
        .toList();
    if (selectedLines.isEmpty) {
      throw StateError(
        'Selecione pelo menos um item da contagem para exportar o PDF.',
      );
    }

    final saveLocation = await getSaveLocation(
      suggestedName: _buildFileName(details.session, suffix: 'folha'),
      acceptedTypeGroups: _pdfTypeGroups,
    );
    if (saveLocation == null) {
      return null;
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Folha de contagem - ${details.session.name}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Aberta por ${details.session.openedBy} em ${AppFormatters.dateTime(details.session.openedAt)}',
          ),
          if (details.session.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Observacoes: ${details.session.notes.trim()}'),
          ],
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Codigo',
              'Item',
              'Categoria',
              'Unidade',
              'Quantidade contada',
              'Observacoes',
            ],
            data: [
              for (final line in selectedLines)
                [line.itemSku, line.itemName, line.category, line.unit, '', ''],
            ],
          ),
        ],
      ),
    );

    return _saveDocument(document, saveLocation.path);
  }

  Future<String?> exportResult(StockCountDetails details) async {
    final selectedLines = details.lines
        .where((line) => line.selectedForExport)
        .toList();
    if (selectedLines.isEmpty) {
      throw StateError(
        'Selecione pelo menos um item da contagem para exportar o PDF.',
      );
    }

    final saveLocation = await getSaveLocation(
      suggestedName: _buildFileName(details.session, suffix: 'resultado'),
      acceptedTypeGroups: _pdfTypeGroups,
    );
    if (saveLocation == null) {
      return null;
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Resultado da contagem - ${details.session.name}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Aberta por ${details.session.openedBy} em ${AppFormatters.dateTime(details.session.openedAt)}',
          ),
          pw.Text(
            details.session.closedAt == null
                ? 'Status: ${details.session.status.label}'
                : 'Fechada por ${details.session.closedBy} em ${AppFormatters.dateTime(details.session.closedAt!)}',
          ),
          if (details.session.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Observacoes de abertura: ${details.session.notes.trim()}'),
          ],
          if (details.session.closingNotes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Observacoes de fechamento: ${details.session.closingNotes.trim()}',
            ),
          ],
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Codigo',
              'Item',
              'Sistema',
              'Contado',
              'Diferenca',
              'Unidade',
              'Contado por',
              'Observacoes',
            ],
            data: [
              for (final line in selectedLines)
                [
                  line.itemSku,
                  line.itemName,
                  AppFormatters.quantity(line.systemQuantity),
                  line.countedQuantity == null
                      ? '-'
                      : AppFormatters.quantity(line.countedQuantity!),
                  line.difference == null
                      ? '-'
                      : AppFormatters.quantity(line.difference!),
                  line.unit,
                  line.countedBy ?? '-',
                  line.lineNote.trim().isEmpty ? '-' : line.lineNote.trim(),
                ],
            ],
          ),
        ],
      ),
    );

    return _saveDocument(document, saveLocation.path);
  }

  String _buildFileName(StockCountSession session, {required String suffix}) {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final normalizedName = session.name
        .trim()
        .replaceAll(RegExp(r'[^\w\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return 'contagem-${normalizedName.isEmpty ? 'estoque' : normalizedName}-$suffix-$timestamp.pdf';
  }

  Future<String> _saveDocument(pw.Document document, String targetPath) async {
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await document.save(), flush: true);
    return targetPath;
  }
}
