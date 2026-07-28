import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/vendor_auth_repository.dart';
import '../api/api_client.dart';
import '../api/api_mappers.dart';

/// [VendorAuthRepository] backed by the beautyhub-api service.
class ApiVendorAuthRepository implements VendorAuthRepository {
  ApiVendorAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (!await _client.hasToken()) return null;
    try {
      final json =
          await _client.get('/auth/me') as Map<String, dynamic>;
      return ApiMappers.userProfile(json);
    } on UnauthenticatedException {
      // Stale token — the client already dropped it.
      return null;
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    ) as Map<String, dynamic>;
    final user = ApiMappers.userProfile(json['user'] as Map<String, dynamic>);
    if (!user.isProvider) {
      throw ApiException(
        403,
        'This account is not a salon owner. '
        'Use the BeautyHub customer app to book appointments.',
      );
    }
    await _client.adoptToken(json['token'] as String);
    return user;
  }

  @override
  Future<void> signOut() => _client.clearToken();

  @override
  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/forgot-password',
        body: {'email': email}, authenticated: false);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post('/auth/reset-password',
        body: {'email': email, 'code': code, 'password': newPassword},
        authenticated: false);
  }
}
