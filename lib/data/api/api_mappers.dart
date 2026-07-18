import '../../domain/entities/review.dart';
import '../../domain/entities/salon.dart';
import '../../domain/entities/salon_service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/vendor_booking.dart';

/// JSON → domain entities. The API sends enum values lowercase to match
/// Dart's `Enum.values.byName`, and ISO-8601 UTC timestamps.
abstract final class ApiMappers {
  static Salon salon(Map<String, dynamic> json) => Salon(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String,
        about: json['about'] as String,
        address: json['address'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        categories: (json['categories'] as List<dynamic>)
            .map((c) => ServiceCategory.values.byName(c as String))
            .toList(),
        openHour: json['openHour'] as int,
        closeHour: json['closeHour'] as int,
        isFeatured: json['isFeatured'] as bool,
        coverSeed: json['coverSeed'] as int,
        services: (json['services'] as List<dynamic>)
            .map((s) => service(s as Map<String, dynamic>))
            .toList(),
        staff: (json['staff'] as List<dynamic>)
            .map((s) => staffMember(s as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List<dynamic>)
            .map((r) => review(r as Map<String, dynamic>))
            .toList(),
      );

  static SalonService service(Map<String, dynamic> json) => SalonService(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        durationMinutes: json['durationMinutes'] as int,
        price: (json['price'] as num).toDouble(),
        category: ServiceCategory.values.byName(json['category'] as String),
      );

  static StaffMember staffMember(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        rating: (json['rating'] as num).toDouble(),
      );

  static Review review(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String,
        date: DateTime.parse(json['date'] as String).toLocal(),
      );

  static UserProfile userProfile(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
      );

  static VendorBooking booking(Map<String, dynamic> json) => VendorBooking(
        id: json['id'] as String,
        customerName: json['customerName'] as String? ?? 'Guest',
        serviceNames:
            (json['serviceNames'] as List<dynamic>).cast<String>().toList(),
        staffName: json['staffName'] as String?,
        start: DateTime.parse(json['start'] as String).toLocal(),
        totalDurationMinutes: json['totalDurationMinutes'] as int,
        totalPrice: (json['totalPrice'] as num).toDouble(),
        status: BookingStatus.values.byName(json['status'] as String),
      );
}
