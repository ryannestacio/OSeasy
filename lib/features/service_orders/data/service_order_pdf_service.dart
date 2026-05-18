import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../domain/service_orders.dart';

class ServiceOrderPdfService {
  Future<Uint8List> exportOrder(ServiceOrderDetails details) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(details, title: 'Ordem de Servico'),
          pw.SizedBox(height: 14),
          _buildPartyTable(details),
          pw.SizedBox(height: 12),
          _buildEquipmentTable(details),
          pw.SizedBox(height: 12),
          _buildServicesTable(details),
          pw.SizedBox(height: 12),
          _buildPartsTable(details),
          pw.SizedBox(height: 12),
          _buildNotesSection(details),
          pw.SizedBox(height: 12),
          _buildTotalsTable(details),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> exportBudget(ServiceOrderDetails details) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(details, title: 'Orcamento da Ordem de Servico'),
          pw.SizedBox(height: 14),
          _buildPartyTable(details),
          pw.SizedBox(height: 12),
          _buildEquipmentTable(details),
          pw.SizedBox(height: 12),
          _buildComplaintSection(details),
          pw.SizedBox(height: 12),
          _buildServicesTable(details),
          pw.SizedBox(height: 12),
          _buildPartsTable(details),
          pw.SizedBox(height: 12),
          _buildTotalsTable(details),
          pw.SizedBox(height: 16),
          pw.Text(
            'Para aprovar este orcamento, assine e devolva para a assistencia tecnica.',
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader(ServiceOrderDetails details, {required String title}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('OS N${details.orderNumber}'),
            pw.Text('Status: ${details.status.label}'),
            pw.Text('Prioridade: ${details.priority.label}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Entrada: ${AppFormatters.dateTime(details.entryAt)}'),
            pw.Text(
              'Pronto: ${details.readyAt == null ? '-' : AppFormatters.dateTime(details.readyAt!)}',
            ),
            pw.Text(
              'Saida: ${details.exitAt == null ? '-' : AppFormatters.dateTime(details.exitAt!)}',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPartyTable(ServiceOrderDetails details) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headers: const ['Cliente', 'Documento', 'Telefone', 'E-mail'],
      data: [
        [
          details.customerName,
          details.customerDocument,
          details.customerPhone,
          details.customerEmail,
        ],
        ['Endereco', details.customerAddress, '', ''],
      ],
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildEquipmentTable(ServiceOrderDetails details) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headers: const [
        'Modelo',
        'Marca/Fabricante',
        'Micro/CPU',
        'RAM/HD',
        'N Serie',
        'N Patrimonio',
      ],
      data: [
        [
          details.equipmentModel,
          details.equipmentBrand,
          details.equipmentMicroCpu,
          details.equipmentRamHd,
          details.equipmentSerialNumber,
          details.equipmentAssetTag,
        ],
        ['Acessorios', details.equipmentAccessories, '', '', '', ''],
      ],
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _buildComplaintSection(ServiceOrderDetails details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Defeito/Reclamacao',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Text(
            details.defectComplaint.trim().isEmpty
                ? '-'
                : details.defectComplaint.trim(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildServicesTable(ServiceOrderDetails details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Mao de obra / Servicos',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: const [
            'Descricao',
            'Tipo',
            'Inicio',
            'Fim',
            'Qtd',
            'Valor',
            'Tecnico',
            'Total',
          ],
          data: [
            for (final line in details.serviceLines)
              [
                line.description,
                line.serviceType,
                line.startTime == null
                    ? '-'
                    : DateFormat('HH:mm').format(line.startTime!),
                line.endTime == null
                    ? '-'
                    : DateFormat('HH:mm').format(line.endTime!),
                AppFormatters.quantity(line.quantity),
                AppFormatters.currency(line.unitPrice),
                line.technicianName,
                AppFormatters.currency(line.totalPrice),
              ],
            if (details.serviceLines.isEmpty) ['', '', '', '', '', '', '', ''],
          ],
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }

  pw.Widget _buildPartsTable(ServiceOrderDetails details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pecas utilizadas',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: const [
            'Peca',
            'Origem',
            'Qtd',
            'Valor un',
            'Total',
            'Tecnico',
          ],
          data: [
            for (final line in details.partLines)
              [
                line.partName,
                line.origin.label,
                AppFormatters.quantity(line.quantity),
                AppFormatters.currency(line.unitPrice),
                AppFormatters.currency(line.totalPrice),
                line.technicianName,
              ],
            if (details.partLines.isEmpty) ['', '', '', '', '', ''],
          ],
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }

  pw.Widget _buildNotesSection(ServiceOrderDetails details) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Defeito/Reclamacao',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          details.defectComplaint.trim().isEmpty
              ? '-'
              : details.defectComplaint.trim(),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Laudo tecnico',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          details.technicalReport.trim().isEmpty
              ? '-'
              : details.technicalReport.trim(),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Observacoes internas',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          details.internalNotes.trim().isEmpty
              ? '-'
              : details.internalNotes.trim(),
        ),
      ],
    );
  }

  pw.Widget _buildTotalsTable(ServiceOrderDetails details) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _moneyRow('Adiantamento', details.advanceAmount),
            _moneyRow('Mao de obra', details.laborAmount),
            _moneyRow('Pecas', details.partsAmount),
            _moneyRow('Deslocamento', details.travelAmount),
            _moneyRow('Terceiros', details.thirdPartyAmount),
            _moneyRow('Outros', details.otherAmount),
            _moneyRow('TOTAL', details.totalAmount, emphasize: true),
          ],
        ),
      ),
    );
  }

  pw.TableRow _moneyRow(String label, double value, {bool emphasize = false}) {
    final style = pw.TextStyle(
      fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: emphasize ? 11 : 10,
    );

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(AppFormatters.currency(value), style: style),
          ),
        ),
      ],
    );
  }
}
