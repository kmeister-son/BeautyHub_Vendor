import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../core/widgets/salon_cover.dart';
import '../../../domain/entities/salon.dart';
import '../../schedule/presentation/providers/schedule_providers.dart';
import 'providers/vendor_providers.dart';

/// The vendor's storefront: how the salon appears to customers, plus the
/// owner's account controls.
class SalonScreen extends ConsumerWidget {
  const SalonScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your credentials to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(vendorAuthRepositoryProvider).signOut();
    ref.invalidate(currentVendorProvider);
    ref.invalidate(vendorSalonProvider);
    ref.invalidate(scheduleProvider);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final salonAsync = ref.watch(vendorSalonProvider);
    final owner = ref.watch(currentVendorProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My salon'),
        actions: [
          IconButton(
            tooltip: 'Edit salon',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/salon/edit'),
          ),
        ],
      ),
      body: salonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your salon.\n$e')),
        data: (salon) => RefreshIndicator(
          onRefresh: () => ref.refresh(vendorSalonProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _StorefrontCard(salon: salon),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        salon.about,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dark_mode_outlined, color: scheme.primary),
                          const SizedBox(width: 14),
                          const Text(
                            'Appearance',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                                value: ThemeMode.system, label: Text('System')),
                            ButtonSegment(
                                value: ThemeMode.light, label: Text('Light')),
                            ButtonSegment(
                                value: ThemeMode.dark, label: Text('Dark')),
                          ],
                          selected: {themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => ref
                              .read(themeModeProvider.notifier)
                              .state = selection.first,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person_outline_rounded,
                          color: scheme.primary),
                      title: Text(
                        owner?.name ?? '…',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      subtitle: Text(owner?.email ?? ''),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: Icon(Icons.logout_rounded, color: scheme.primary),
                      title: const Text(
                        'Sign out',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      onTap: () => _signOut(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'BeautyHub Vendor v0.1.0 · MVP',
                  style:
                      TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Customer-facing header: cover, name, tagline, rating, address, hours.
class _StorefrontCard extends StatelessWidget {
  const _StorefrontCard({required this.salon});

  final Salon salon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: SalonCover(
              seed: salon.coverSeed,
              emoji: salon.categories.isEmpty
                  ? '💈'
                  : salon.categories.first.emoji,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        salon.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    RatingBadge(
                        rating: salon.rating, reviewCount: salon.reviewCount),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  salon.tagline,
                  style: TextStyle(
                      fontSize: 13.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        salon.address,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Text(
                      'Open ${salon.openHour.toString().padLeft(2, '0')}:00'
                      ' – ${salon.closeHour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
