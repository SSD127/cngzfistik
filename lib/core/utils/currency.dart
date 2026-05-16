import 'package:intl/intl.dart';

class Currency {
  Currency._();

  static final _formatter = NumberFormat('#,##0.00', 'tr_TR');

  /// Kuruşu TL string'e çevirir (Gereksinim: para birimi integer kuruş)
  static String formatCents(int cents) {
    return '${_formatter.format(cents / 100)} ₺';
  }

  /// miktar × kur × içGramaj = toplam kuruş (Gereksinim 6.2)
  static int calculateSaleAmountCents(
    double quantityKg,
    int pricePerKgCents,
    double innerGramRatio,
  ) {
    return (quantityKg * pricePerKgCents * innerGramRatio).round();
  }
}
