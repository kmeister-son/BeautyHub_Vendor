import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/vendor_auth_repository.dart';
import '../api/api_client.dart';

/// In-memory [VendorAuthRepository] for widget tests and offline demos.
/// Accepts any `owner-*` email with [password]; other credentials behave
/// like the API (401 for bad password, 403 for non-provider accounts).
class MockVendorAuthRepository implements VendorAuthRepository {
  MockVendorAuthRepository({this.latency = Duration.zero});

  static const password = 'provider_dev_password';

  final Duration latency;
  UserProfile? _current;

  @override
  Future<UserProfile?> getCurrentUser() async {
    await Future<void>.delayed(latency);
    return _current;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    if (password != MockVendorAuthRepository.password) {
      throw ApiException(401, 'Invalid credentials');
    }
    if (!email.startsWith('owner-')) {
      throw ApiException(
        403,
        'This account is not a salon owner. '
        'Use the BeautyHub customer app to book appointments.',
      );
    }
    return _current = UserProfile(
      id: 'provider-1',
      email: email,
      name: 'Salon Owner',
      role: 'provider',
    );
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(latency);
    _current = null;
  }
}
