/// A customer review left on a salon.
class Review {
  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;
}
