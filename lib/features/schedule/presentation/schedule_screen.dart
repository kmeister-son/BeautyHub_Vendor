import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/entities/vendor_booking.dart';
import 'providers/schedule_providers.dart';

/// The vendor's day view: pick a date, see every confirmed appointment and
/// the day's takings at a glance.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(scheduleDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(scheduleDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(scheduleDateProvider);
    final bookingsAsync = ref.watch(scheduleProvider);
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Today' : Formatters.day(date)),
        actions: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => ref.read(scheduleDateProvider.notifier).state =
                date.subtract(const Duration(days: 1)),
          ),
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickDate(context, ref),
          ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => ref.read(scheduleDateProvider.notifier).state =
                date.add(const Duration(days: 1)),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load the schedule.\n$e')),
        data: (bookings) {
          // Requests the owner still has to answer sit above the day itself;
          // they hold their slot but aren't part of the day's takings yet.
          final requests = bookings.where((b) => b.isPending).toList();
          final booked = bookings.where((b) => !b.isPending).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(scheduleProvider.future),
            child: bookings.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: EmptyState(
                            icon: Icons.event_available_rounded,
                            title: 'No appointments',
                            message: isToday
                                ? 'Nothing booked for today yet — enjoy the calm.'
                                : 'Nothing booked for ${Formatters.dayLong(date)}.',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      _DaySummaryCard(bookings: booked),
                      const SizedBox(height: 16),
                      if (requests.isNotEmpty) ...[
                        _RequestsHeader(count: requests.length),
                        const SizedBox(height: 10),
                        for (final booking in requests) ...[
                          _RequestCard(booking: booking),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 6),
                      ],
                      for (final booking in booked) ...[
                        _AppointmentCard(booking: booking),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// Takings strip: appointments, billed hours and revenue for the day.
class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({required this.bookings});

  final List<VendorBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final minutes = bookings.fold<int>(
        0, (sum, b) => sum + b.totalDurationMinutes);
    final revenue = bookings.fold<double>(0, (sum, b) => sum + b.totalPrice);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _SummaryStat(
              label: 'Appointments',
              value: '${bookings.length}',
            ),
            _SummaryStat(label: 'Booked time', value: Formatters.duration(minutes)),
            _SummaryStat(label: 'Revenue', value: Formatters.money(revenue)),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsHeader extends StatelessWidget {
  const _RequestsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.pending_actions_rounded, size: 19, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          count == 1 ? '1 request' : '$count requests',
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'awaiting your answer',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// A booking waiting on the owner: same details as an appointment, plus the
/// accept/decline actions and how long is left to answer.
class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.booking});

  final VendorBooking booking;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _submitting = false;

  Future<void> _respond({required bool accept}) async {
    setState(() => _submitting = true);
    final repo = ref.read(vendorRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final name = widget.booking.customerName;
    try {
      accept
          ? await repo.acceptBooking(widget.booking.id)
          : await repo.declineBooking(widget.booking.id);
      messenger.showSnackBar(SnackBar(
        content: Text(
          accept ? "$name's booking is confirmed." : "Declined $name's request.",
        ),
      ));
    } catch (e) {
      // Usually the request lapsed or was answered elsewhere; a refresh
      // shows the truth either way.
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not answer that request. $e')),
      );
    }
    ref.invalidate(scheduleProvider);
  }

  /// "Expires in 3h" / "Expires in 45min" — how long the customer waits.
  String? get _expiryLabel {
    final expiresAt = widget.booking.expiresAt;
    if (expiresAt == null) return null;
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    return 'Expires in ${Formatters.duration(left.inMinutes)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final booking = widget.booking;
    final expiry = _expiryLabel;
    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.28),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      Formatters.time(booking.start),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      Formatters.time(booking.end),
                      style: TextStyle(
                          fontSize: 12.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.serviceNames.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                      if (booking.staffName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'with ${booking.staffName}',
                          style: TextStyle(
                              fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  Formatters.money(booking.totalPrice),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (expiry != null) ...[
              const SizedBox(height: 10),
              Text(
                expiry,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => _respond(accept: false),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _respond(accept: true),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final VendorBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final faded = booking.isPast;
    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    Formatters.time(booking.start),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    Formatters.time(booking.end),
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Container(
                width: 3,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.serviceNames.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                    if (booking.staffName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'with ${booking.staffName}',
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Formatters.money(booking.totalPrice),
                style:
                    const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
