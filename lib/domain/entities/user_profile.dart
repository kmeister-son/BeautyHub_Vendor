/// The signed-in salon owner behind the current session.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;

  /// Lowercase API role (`customer`, `provider`, `admin`). The vendor app
  /// only ever adopts `provider` identities.
  final String role;

  bool get isProvider => role == 'provider';
}
