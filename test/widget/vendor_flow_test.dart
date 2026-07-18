import 'package:beautyhub_vendor/app.dart';
import 'package:beautyhub_vendor/core/di/providers.dart';
import 'package:beautyhub_vendor/data/repositories/mock_vendor_auth_repository.dart';
import 'package:beautyhub_vendor/data/repositories/mock_vendor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      // Widget tests stay hermetic on the in-memory mocks.
      overrides: [
        vendorAuthRepositoryProvider
            .overrideWithValue(MockVendorAuthRepository()),
        vendorRepositoryProvider.overrideWithValue(MockVendorRepository()),
      ],
      child: const BeautyHubVendorApp(),
    ),
  );
  // Splash hands off after 2 seconds (no-op when the shared router is
  // already past it from an earlier test).
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(
      find.byType(TextFormField).first, 'owner-velvet@beautyhub.app');
  await tester.enterText(find.byType(TextFormField).last,
      MockVendorAuthRepository.password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('owner signs in, reads the day, manages the menu, signs out',
      (tester) async {
    await _pumpApp(tester);

    // Signed out → splash lands on login.
    expect(find.text('Welcome, partner 💜'), findsOneWidget);

    // Empty submit surfaces validation, not a request.
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await _signIn(tester);

    // Schedule: today's two bookings and the takings strip.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(r'$80'), findsOneWidget);
    expect(find.text('Thandi M'), findsOneWidget);
    expect(find.text('with Amara Osei'), findsOneWidget);

    // Services: the menu renders and a new service can be added.
    await _openTab(tester, 'Services');
    expect(find.text('Signature cut'), findsOneWidget);
    expect(find.text('Gel manicure'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Beard trim');
    await tester.enterText(fields.at(1), 'Shape and line-up.');
    await tester.enterText(fields.at(2), '20');
    await tester.enterText(fields.at(3), '15');
    await tester.tap(find.widgetWithText(FilledButton, 'Add service'));
    await tester.pumpAndSettle();
    expect(find.text('Beard trim'), findsOneWidget);

    // Team: staff render with their roles.
    await _openTab(tester, 'Team');
    expect(find.text('Amara Osei'), findsOneWidget);
    expect(find.text('Senior stylist'), findsOneWidget);

    // My salon: storefront and account, then sign out back to login.
    await _openTab(tester, 'My salon');
    expect(find.text('Velvet & Vine'), findsOneWidget);

    await tester.dragUntilVisible(
        find.text('Sign out'), find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, partner 💜'), findsOneWidget);
  });

  testWidgets('customer credentials are turned away with a clear message',
      (tester) async {
    await _pumpApp(tester);
    expect(find.text('Welcome, partner 💜'), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).first, 'thandi@example.com');
    await tester.enterText(find.byType(TextFormField).last,
        MockVendorAuthRepository.password);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not a salon owner'), findsOneWidget);

    // A wrong password reads as bad credentials, not a role problem.
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}
