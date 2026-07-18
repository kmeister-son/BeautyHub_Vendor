import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        data: (bookings) => RefreshIndicator(
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
                    _DaySummaryCard(bookings: bookings),
                    const SizedBox(height: 16),
                    for (final booking in bookings) ...[
                      _AppointmentCard(booking: booking),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
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
