import 'package:intl/intl.dart';

import '../../domain/entities/service_category.dart';

/// Central formatting helpers so currency/locale changes happen in one place.
///
/// BeautyHub's launch market is South Africa: prices are rands, formatted per
/// the en_ZA locale ("R250", "R1 234,50"). Entering a new market means
/// changing [currencyCode], [_currencySymbol], and [_locale] here — nowhere
/// else in the app names a currency. Payment integrations (Stripe) must use
/// [currencyCode] so charges stay in the same currency as displayed prices.
abstract final class Formatters {
  static const currencyCode = 'ZAR';
  static const _currencySymbol = 'R';
  static const _locale = 'en_ZA';

  static final _money = NumberFormat.currency(
      locale: _locale, symbol: _currencySymbol, decimalDigits: 0);
  static final _moneyPrecise =
      NumberFormat.currency(locale: _locale, symbol: _currencySymbol);

  static String money(double value) =>
      value == value.roundToDouble() ? _money.format(value) : _moneyPrecise.format(value);

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  static String day(DateTime date) => DateFormat('EEE, d MMM').format(date);

  static String dayLong(DateTime date) => DateFormat('EEEE, d MMMM').format(date);

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
}

/// Icon-name mapping lives with the presentation helpers, keeping the
/// domain enum free of Flutter imports.
extension ServiceCategoryX on ServiceCategory {
  String get emoji => switch (this) {
        ServiceCategory.haircut => '💇',
        ServiceCategory.barber => '💈',
        ServiceCategory.nails => '💅',
        ServiceCategory.spa => '🧖',
        ServiceCategory.makeup => '💄',
        ServiceCategory.skincare => '✨',
      };
}
