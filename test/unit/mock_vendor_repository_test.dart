import 'package:beautyhub_vendor/data/repositories/mock_vendor_repository.dart';
import 'package:beautyhub_vendor/domain/entities/service_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service CRUD round-trips through the salon payload', () async {
    final repo = MockVendorRepository();

    final created = await repo.createService(
      name: 'Beard trim',
      description: 'Shape and line-up.',
      durationMinutes: 20,
      price: 15,
      category: ServiceCategory.barber,
    );
    var salon = await repo.getSalon();
    expect(salon.services.map((s) => s.name), contains('Beard trim'));

    await repo.updateService(created.id, price: 18);
    salon = await repo.getSalon();
    expect(
        salon.services.singleWhere((s) => s.id == created.id).price, 18);

    await repo.deleteService(created.id);
    salon = await repo.getSalon();
    expect(salon.services.map((s) => s.id), isNot(contains(created.id)));
  });

  test('salon updates only touch the provided fields', () async {
    final repo = MockVendorRepository();
    final before = await repo.getSalon();

    final after = await repo.updateSalon(tagline: 'New tagline');

    expect(after.tagline, 'New tagline');
    expect(after.name, before.name);
    expect(after.openHour, before.openHour);
  });

  test('bookings are filtered to the requested day', () async {
    final repo = MockVendorRepository();
    final today = DateTime.now();

    expect(await repo.getBookings(today), hasLength(2));
    expect(
        await repo.getBookings(today.add(const Duration(days: 1))), isEmpty);
  });
}
