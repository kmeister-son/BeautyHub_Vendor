/// Top-level service categories a customer can browse.
enum ServiceCategory {
  haircut('Haircut'),
  barber('Barber'),
  nails('Nails'),
  spa('Spa'),
  makeup('Makeup'),
  skincare('Skincare');

  const ServiceCategory(this.label);

  final String label;
}
