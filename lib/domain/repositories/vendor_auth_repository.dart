import '../entities/user_profile.dart';

/// Identity for the vendor app. Unlike the customer app there is no guest:
/// provider accounts are provisioned by BeautyHub, so the app is signed out
/// until [signIn] succeeds.
abstract interface class VendorAuthRepository {
  /// The stored identity, or null when signed out (or the token went stale).
  Future<UserProfile?> getCurrentUser();

  /// Signs in and keeps the token only for provider accounts; customer
  /// credentials are rejected so vendors don't get a broken half-session.
  Future<UserProfile> signIn({required String email, required String password});

  Future<void> signOut();

  /// Requests a one-time reset code for [email]. Always succeeds, whether
  /// or not an account exists (no account probing).
  Future<void> requestPasswordReset(String email);

  /// Sets a new password using the emailed one-time [code].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
