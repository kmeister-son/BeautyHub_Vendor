import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/salon.dart';
import '../../../../domain/entities/user_profile.dart';

/// The signed-in salon owner, or null when signed out.
/// Invalidate after sign-in/out (together with [vendorSalonProvider]).
final currentVendorProvider = FutureProvider<UserProfile?>(
  (ref) => ref.watch(vendorAuthRepositoryProvider).getCurrentUser(),
);

/// The salon this provider owns — services, staff, and profile all read
/// from here. Invalidate after any mutation.
final vendorSalonProvider = FutureProvider<Salon>(
  (ref) => ref.watch(vendorRepositoryProvider).getSalon(),
);
