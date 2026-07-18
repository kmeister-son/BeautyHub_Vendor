enum BookingStatus { confirmed, cancelled }

/// An appointment on the salon's calendar, as the vendor sees it.
class VendorBooking {
  const VendorBooking({
    required this.id,
    required this.customerName,
    required this.serviceNames,
    required this.staffName,
    required this.start,
    required this.totalDurationMinutes,
    required this.totalPrice,
    required this.status,
  });

  final String id;
  final String customerName;
  final List<String> serviceNames;

  /// Null means "any available professional".
  final String? staffName;

  final DateTime start;
  final int totalDurationMinutes;
  final double totalPrice;
  final BookingStatus status;

  DateTime get end => start.add(Duration(minutes: totalDurationMinutes));

  bool get isPast => end.isBefore(DateTime.now());
}
