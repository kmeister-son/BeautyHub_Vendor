import 'service_category.dart';

/// A single bookable service offered by a salon (e.g. "Skin fade", "Gel manicure").
class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final ServiceCategory category;
}
