/// A professional working at a salon whom the customer can book.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
  });

  final String id;
  final String name;
  final String role;
  final double rating;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
