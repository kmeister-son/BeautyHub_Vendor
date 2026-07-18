import '../entities/salon.dart';
import '../entities/salon_service.dart';
import '../entities/service_category.dart';
import '../entities/staff_member.dart';
import '../entities/vendor_booking.dart';

/// Everything a signed-in provider can do to the salon they own. All calls
/// are scoped server-side to that salon.
abstract interface class VendorRepository {
  Future<Salon> getSalon();

  /// Partial update: null fields are left unchanged.
  Future<Salon> updateSalon({
    String? name,
    String? tagline,
    String? about,
    String? address,
    int? openHour,
    int? closeHour,
  });

  Future<SalonService> createService({
    required String name,
    required String description,
    required int durationMinutes,
    required double price,
    required ServiceCategory category,
  });

  Future<SalonService> updateService(
    String id, {
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    ServiceCategory? category,
  });

  Future<void> deleteService(String id);

  Future<StaffMember> createStaff({required String name, required String role});

  Future<StaffMember> updateStaff(String id, {String? name, String? role});

  Future<void> deleteStaff(String id);

  /// Confirmed bookings for [date] (whole day, salon-local), oldest first.
  Future<List<VendorBooking>> getBookings(DateTime date);
}
