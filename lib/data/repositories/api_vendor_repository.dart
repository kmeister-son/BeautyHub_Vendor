import '../../domain/entities/salon.dart';
import '../../domain/entities/salon_service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/vendor_booking.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../api/api_client.dart';
import '../api/api_mappers.dart';

/// [VendorRepository] backed by the beautyhub-api `/provider` endpoints,
/// which are scoped server-side to the caller's salon.
class ApiVendorRepository implements VendorRepository {
  ApiVendorRepository(this._client);

  final ApiClient _client;

  /// Drops null values so PATCH bodies only carry the changed fields.
  Map<String, Object> _compact(Map<String, Object?> fields) => {
        for (final MapEntry(:key, :value) in fields.entries)
          if (value != null) key: value,
      };

  @override
  Future<Salon> getSalon() async {
    final json = await _client.get('/provider/salon') as Map<String, dynamic>;
    return ApiMappers.salon(json);
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
    final json = await _client.patch('/provider/salon', body: _compact({
      'name': name,
      'tagline': tagline,
      'about': about,
      'address': address,
      'openHour': openHour,
      'closeHour': closeHour,
      'autoConfirmBookings': autoConfirmBookings,
    })) as Map<String, dynamic>;
    return ApiMappers.salon(json);
  }

  @override
  Future<SalonService> createService({
    required String name,
    required String description,
    required int durationMinutes,
    required double price,
    required ServiceCategory category,
  }) async {
    final json = await _client.post('/provider/services', body: {
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'category': category.name,
    }) as Map<String, dynamic>;
    return ApiMappers.service(json);
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
    final json =
        await _client.patch('/provider/services/$id', body: _compact({
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'price': price,
      'category': category?.name,
    })) as Map<String, dynamic>;
    return ApiMappers.service(json);
  }

  @override
  Future<void> deleteService(String id) =>
      _client.delete('/provider/services/$id');

  @override
  Future<StaffMember> createStaff({
    required String name,
    required String role,
  }) async {
    final json = await _client.post('/provider/staff',
        body: {'name': name, 'role': role}) as Map<String, dynamic>;
    return ApiMappers.staffMember(json);
  }

  @override
  Future<StaffMember> updateStaff(String id, {String? name, String? role}) async {
    final json = await _client.patch('/provider/staff/$id',
        body: _compact({'name': name, 'role': role})) as Map<String, dynamic>;
    return ApiMappers.staffMember(json);
  }

  @override
  Future<void> deleteStaff(String id) => _client.delete('/provider/staff/$id');

  @override
  Future<List<VendorBooking>> getBookings(DateTime date) async {
    final day = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final json = await _client.get('/provider/bookings',
        query: {'date': day}) as List<dynamic>;
    return json
        .map((b) => ApiMappers.booking(b as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VendorBooking> acceptBooking(String id) => _respond(id, 'accept');

  @override
  Future<VendorBooking> declineBooking(String id) => _respond(id, 'decline');

  Future<VendorBooking> _respond(String id, String verb) async {
    final json = await _client.post('/provider/bookings/$id/$verb')
        as Map<String, dynamic>;
    return ApiMappers.booking(json);
  }
}
