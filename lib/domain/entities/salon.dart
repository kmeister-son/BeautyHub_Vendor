import 'review.dart';
import 'salon_service.dart';
import 'service_category.dart';
import 'staff_member.dart';

/// A vendor on the marketplace: a salon, barbershop, spa, etc.
class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.tagline,
    required this.about,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.openHour,
    required this.closeHour,
    required this.isFeatured,
    required this.coverSeed,
    required this.services,
    required this.staff,
    required this.reviews,
  });

  final String id;
  final String name;
  final String tagline;
  final String about;
  final String address;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final List<ServiceCategory> categories;

  /// Opening hours as hours of the day (24h), e.g. 9 → 09:00.
  final int openHour;
  final int closeHour;

  final bool isFeatured;

  /// Deterministic seed used by the UI to pick a cover gradient
  /// until real vendor photos are wired in.
  final int coverSeed;

  final List<SalonService> services;
  final List<StaffMember> staff;
  final List<Review> reviews;

  double get startingPrice =>
      services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
}
