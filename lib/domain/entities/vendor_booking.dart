enum BookingStatus { pending, confirmed, declined, expired, cancelled }

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
    this.expiresAt,
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

  /// When a pending request lapses if the owner doesn't respond.
  /// Only set while [status] is [BookingStatus.pending].
  final DateTime? expiresAt;

  DateTime get end => start.add(Duration(minutes: totalDurationMinutes));

  bool get isPast => end.isBefore(DateTime.now());

  bool get isPending => status == BookingStatus.pending;

  VendorBooking copyWith({BookingStatus? status, DateTime? expiresAt}) =>
      VendorBooking(
        id: id,
        customerName: customerName,
        serviceNames: serviceNames,
        staffName: staffName,
        start: start,
        totalDurationMinutes: totalDurationMinutes,
        totalPrice: totalPrice,
        status: status ?? this.status,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}
