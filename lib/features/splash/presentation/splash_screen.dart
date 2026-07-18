import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_profile.dart';

/// Brand splash shown on launch. Checks for a stored provider session and
/// hands off to the schedule, or to login when signed out.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _holdDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Resolve the session while the brand holds on screen.
    final hold = Future<void>.delayed(_holdDuration);
    UserProfile? user;
    try {
      user = await ref.read(vendorAuthRepositoryProvider).getCurrentUser();
    } catch (_) {
      // Offline or server down: land on login, which shows real errors.
      user = null;
    }
    await hold;
    if (!mounted) return;
    context.go(user != null && user.isProvider ? '/schedule' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9F7AEA), AppColors.seed, Color(0xFF5B21B6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 72, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'BeautyHub Vendor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Run your salon from your pocket',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
