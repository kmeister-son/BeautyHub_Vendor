import '../../domain/entities/review.dart';
import '../../domain/entities/salon.dart';
import '../../domain/entities/salon_service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/vendor_booking.dart';
import '../../domain/repositories/vendor_repository.dart';

/// In-memory [VendorRepository] for widget tests and offline demos: one
/// salon with a couple of services, staff, and today's bookings.
class MockVendorRepository implements VendorRepository {
  MockVendorRepository({this.latency = Duration.zero});

  final Duration latency;
  int _nextId = 1;

  String _name = 'Velvet & Vine';
  String _tagline = 'Hair artistry in the heart of town';
  String _about = 'A calm studio focused on cuts, colour and care.';
  String _address = '12 Rose Lane, City Centre';
  int _openHour = 9;
  int _closeHour = 18;
  bool _autoConfirmBookings = false;

  final List<SalonService> _services = [
    const SalonService(
      id: 'svc-1',
      name: 'Signature cut',
      description: 'Consultation, wash, precision cut and style.',
      durationMinutes: 60,
      price: 45,
      category: ServiceCategory.haircut,
    ),
    const SalonService(
      id: 'svc-2',
      name: 'Gel manicure',
      description: 'Shape, cuticle care and long-wear gel polish.',
      durationMinutes: 45,
      price: 35,
      category: ServiceCategory.nails,
    ),
  ];

  final List<StaffMember> _staff = [
    const StaffMember(id: 'stf-1', name: 'Amara Osei', role: 'Senior stylist', rating: 4.9),
    const StaffMember(id: 'stf-2', name: 'Lindiwe Dube', role: 'Nail artist', rating: 4.7),
  ];

  late final List<VendorBooking> _bookings = () {
    final today = DateTime.now();
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(today.year, today.month, today.day, hour, minute);
    return [
      VendorBooking(
        id: 'bk-3',
        customerName: 'Naledi K',
        serviceNames: const ['Gel manicure'],
        staffName: 'Lindiwe Dube',
        start: at(16),
        totalDurationMinutes: 45,
        totalPrice: 35,
        status: BookingStatus.pending,
        expiresAt: today.add(const Duration(hours: 20)),
      ),
      VendorBooking(
        id: 'bk-1',
        customerName: 'Thandi M',
        serviceNames: const ['Signature cut'],
        staffName: 'Amara Osei',
        start: at(10),
        totalDurationMinutes: 60,
        totalPrice: 45,
        status: BookingStatus.confirmed,
      ),
      VendorBooking(
        id: 'bk-2',
        customerName: 'Guest',
        serviceNames: const ['Gel manicure'],
        staffName: null,
        start: at(14, 30),
        totalDurationMinutes: 45,
        totalPrice: 35,
        status: BookingStatus.confirmed,
      ),
    ];
  }();

  Salon _salon() => Salon(
        id: 'salon-1',
        name: _name,
        tagline: _tagline,
        about: _about,
        address: _address,
        distanceKm: 0,
        rating: 4.8,
        reviewCount: 132,
        categories: _services.map((s) => s.category).toSet().toList(),
        openHour: _openHour,
        closeHour: _closeHour,
        isFeatured: true,
        coverSeed: 0,
        autoConfirmBookings: _autoConfirmBookings,
        services: List.unmodifiable(_services),
        staff: List.unmodifiable(_staff),
        reviews: const <Review>[],
      );

  @override
  Future<Salon> getSalon() async {
    await Future<void>.delayed(latency);
    return _salon();
  }

  @override
  Future<Salon> updateSalon({
    String? name,
    String? tagline,
    String? about,
    String? address,
    int? openHour,
    int? closeHour,
    bool? autoConfirmBookings,
  }) async {
    await Future<void>.delayed(latency);
    _name = name ?? _name;
    _tagline = tagline ?? _tagline;
    _about = about ?? _about;
    _address = address ?? _address;
    _openHour = openHour ?? _openHour;
    _closeHour = closeHour ?? _closeHour;
    _autoConfirmBookings = autoConfirmBookings ?? _autoConfirmBookings;
    return _salon();
  }

  @override
  Future<SalonService> createService({
    required String name,
    required String description,
    required int durationMinutes,
    required double price,
    required ServiceCategory category,
  }) async {
    await Future<void>.delayed(latency);
    final service = SalonService(
      id: 'svc-new-${_nextId++}',
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      category: category,
    );
    _services.add(service);
    return service;
  }

  @override
  Future<SalonService> updateService(
    String id, {
    String? name,
    String? description,
    int? durationMinutes,
    double? price,
    ServiceCategory? category,
  }) async {
    await Future<void>.delayed(latency);
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) throw StateError('Service not found: $id');
    final old = _services[index];
    final updated = SalonService(
      id: old.id,
      name: name ?? old.name,
      description: description ?? old.description,
      durationMinutes: durationMinutes ?? old.durationMinutes,
      price: price ?? old.price,
      category: category ?? old.category,
    );
    return _services[index] = updated;
  }

  @override
  Future<void> deleteService(String id) async {
    await Future<void>.delayed(latency);
    _services.removeWhere((s) => s.id == id);
  }

  @override
  Future<StaffMember> createStaff({
    required String name,
    required String role,
  }) async {
    await Future<void>.delayed(latency);
    final member = StaffMember(
      id: 'stf-new-${_nextId++}',
      name: name,
      role: role,
      rating: 5,
    );
    _staff.add(member);
    return member;
  }

  @override
  Future<StaffMember> updateStaff(String id, {String? name, String? role}) async {
    await Future<void>.delayed(latency);
    final index = _staff.indexWhere((s) => s.id == id);
    if (index == -1) throw StateError('Staff member not found: $id');
    final old = _staff[index];
    final updated = StaffMember(
      id: old.id,
      name: name ?? old.name,
      role: role ?? old.role,
      rating: old.rating,
    );
    return _staff[index] = updated;
  }

  @override
  Future<void> deleteStaff(String id) async {
    await Future<void>.delayed(latency);
    _staff.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<VendorBooking>> getBookings(DateTime date) async {
    await Future<void>.delayed(latency);
    return _bookings
        .where((b) =>
            b.start.year == date.year &&
            b.start.month == date.month &&
            b.start.day == date.day)
        .where((b) => b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<VendorBooking> acceptBooking(String id) =>
      _respond(id, BookingStatus.confirmed);

  @override
  Future<VendorBooking> declineBooking(String id) =>
      _respond(id, BookingStatus.declined);

  /// Mirrors the API's guard: only a live pending request transitions.
  Future<VendorBooking> _respond(String id, BookingStatus status) async {
    await Future<void>.delayed(latency);
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) throw StateError('Booking not found: $id');
    if (!_bookings[index].isPending) {
      throw StateError('This request is no longer pending.');
    }
    return _bookings[index] = _bookings[index].copyWith(status: status);
  }
}
