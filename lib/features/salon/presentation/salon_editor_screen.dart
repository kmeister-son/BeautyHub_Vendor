import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/salon.dart';
import '../../auth/presentation/widgets/auth_error_banner.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import 'providers/vendor_providers.dart';

/// Edit form for the salon's customer-facing profile.
class SalonEditorScreen extends ConsumerStatefulWidget {
  const SalonEditorScreen({super.key});

  @override
  ConsumerState<SalonEditorScreen> createState() => _SalonEditorScreenState();
}

class _SalonEditorScreenState extends ConsumerState<SalonEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _about = TextEditingController();
  final _address = TextEditingController();
  int _openHour = 9;
  int _closeHour = 18;
  bool _autoConfirmBookings = true;

  bool _prefilled = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _about.dispose();
    _address.dispose();
    super.dispose();
  }

  void _prefill(Salon salon) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = salon.name;
    _tagline.text = salon.tagline;
    _about.text = salon.about;
    _address.text = salon.address;
    _openHour = salon.openHour;
    _closeHour = salon.closeHour;
    _autoConfirmBookings = salon.autoConfirmBookings;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_closeHour <= _openHour) {
      setState(() => _error = 'Closing time must be after opening time.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(vendorRepositoryProvider).updateSalon(
            name: _name.text.trim(),
            tagline: _tagline.text.trim(),
            about: _about.text.trim(),
            address: _address.text.trim(),
            openHour: _openHour,
            closeHour: _closeHour,
            autoConfirmBookings: _autoConfirmBookings,
          );
      ref.invalidate(vendorSalonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not save your salon. $e';
      });
    }
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    if (!_prefilled) {
      // The salon tab is already loaded when the editor opens from it.
      final salon = ref.watch(vendorSalonProvider).valueOrNull;
      if (salon == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit salon')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      _prefill(salon);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit salon')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AuthTextField(
                label: 'Salon name',
                controller: _name,
                validator: (v) => _required(v, 'Enter your salon name'),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Tagline',
                controller: _tagline,
                hint: 'One line customers see first',
                validator: (v) => _required(v, 'Enter a tagline'),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'About',
                controller: _about,
                hint: 'Tell customers about your salon',
                validator: (v) => _required(v, 'Tell customers about your salon'),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Address',
                controller: _address,
                textInputAction: TextInputAction.done,
                validator: (v) => _required(v, 'Enter your address'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HourPicker(
                      label: 'Opens',
                      value: _openHour,
                      first: 0,
                      last: 23,
                      onChanged: (hour) => setState(() => _openHour = hour),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HourPicker(
                      label: 'Closes',
                      value: _closeHour,
                      first: 1,
                      last: 24,
                      onChanged: (hour) => setState(() => _closeHour = hour),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _autoConfirmBookings,
                onChanged: (value) =>
                    setState(() => _autoConfirmBookings = value),
                title: const Text(
                  'Confirm bookings instantly',
                  style:
                      TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _autoConfirmBookings
                      ? 'Customers get an instant confirmation when they book.'
                      : 'Every booking arrives as a request you accept or '
                          'decline. Requests expire after a day.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: 26),
              FilledButton(
                onPressed: _submitting ? null : _save,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.label,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int first;
  final int last;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: value,
          items: [
            for (var hour = first; hour <= last; hour++)
              DropdownMenuItem(
                value: hour,
                child: Text('${hour.toString().padLeft(2, '0')}:00'),
              ),
          ],
          onChanged: (hour) {
            if (hour != null) onChanged(hour);
          },
        ),
      ],
    );
  }
}
