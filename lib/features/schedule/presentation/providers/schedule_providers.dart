import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/vendor_booking.dart';

/// The day the schedule tab is looking at (date only, local time).
final scheduleDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Confirmed bookings for the selected day, oldest first.
final scheduleProvider = FutureProvider<List<VendorBooking>>(
  (ref) => ref
      .watch(vendorRepositoryProvider)
      .getBookings(ref.watch(scheduleDateProvider)),
);
