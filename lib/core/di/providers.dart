import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/api_vendor_auth_repository.dart';
import '../../data/repositories/api_vendor_repository.dart';
import '../../domain/repositories/vendor_auth_repository.dart';
import '../../domain/repositories/vendor_repository.dart';

/// Composition root. Bound to the beautyhub-api service; widget tests
/// override these with the in-memory mocks from data/repositories/.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final vendorAuthRepositoryProvider = Provider<VendorAuthRepository>(
  (ref) => ApiVendorAuthRepository(ref.watch(apiClientProvider)),
);

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => ApiVendorRepository(ref.watch(apiClientProvider)),
);
