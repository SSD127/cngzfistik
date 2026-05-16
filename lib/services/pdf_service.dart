import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency.dart';

class PdfService {
  /// Satış/alım/kasa hareketi fişi (Gereksinim 9)
  static Future<void> printReceipt({
    required String receiptNumber,
    required String type,
    required String customerName,
    required DateTime date,
    required int totalAmountCents,
    required int cashBalanceAfterCents,
    String? pistachioType,
    double? quantityKg,
    int? pricePerKgCents,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Fıstık Komisyon',
              style: pw.TextStyle(font: font, fontSize: 18),
            ),
          ),
          pw.Divider(),
          _row(font, 'Fiş No', receiptNumber),
          _row(font, 'Tarih',
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'),
          _row(font, 'Müşteri', customerName),
          _row(font, 'İşlem Türü', _localizeType(type)),
          if (pistachioType != null) _row(font, 'Fıstık Cinsi', pistachioType),
          if (quantityKg != null)
            _row(font, 'Miktar', '${quantityKg.toStringAsFixed(2)} kg'),
          if (pricePerKgCents != null)
            _row(font, 'Kur', Currency.formatCents(pricePerKgCents) + '/kg'),
          pw.Divider(),
          _row(font, 'Toplam', Currency.formatCents(totalAmountCents),
              bold: true),
          _row(font, 'Kasa Bakiyesi',
              Currency.formatCents(cashBalanceAfterCents)),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (fmt) async => pdf.save());
  }

  static pw.Widget _row(pw.Font font, String label, String value,
      {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight: bold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  static Future<pw.Font> _loadFont() async {
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  static String _localizeType(String type) => switch (type) {
        'sale' => 'Satış',
        'purchase' => 'Alım',
        'cash_deposit' => 'Para Girişi',
        'cash_withdrawal' => 'Para Çıkışı',
        'vault_deposit' => 'Kasa Emaneti Girişi',
        'vault_withdrawal' => 'Kasa Emaneti İadesi',
        _ => type,
      };
}
