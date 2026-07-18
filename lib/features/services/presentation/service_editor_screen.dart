import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/salon_service.dart';
import '../../../domain/entities/service_category.dart';
import '../../auth/presentation/widgets/auth_error_banner.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../../salon/presentation/providers/vendor_providers.dart';

/// Create/edit form for one service. [serviceId] null means "add new".
class ServiceEditorScreen extends ConsumerStatefulWidget {
  const ServiceEditorScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  ConsumerState<ServiceEditorScreen> createState() =>
      _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends ConsumerState<ServiceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController();
  final _price = TextEditingController();
  ServiceCategory _category = ServiceCategory.haircut;

  bool _prefilled = false;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.serviceId != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  void _prefill(SalonService service) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = service.name;
    _description.text = service.description;
    _duration.text = '${service.durationMinutes}';
    _price.text = service.price == service.price.roundToDouble()
        ? '${service.price.round()}'
        : '${service.price}';
    _category = service.category;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repo = ref.read(vendorRepositoryProvider);
    try {
      if (_isEditing) {
        await repo.updateService(
          widget.serviceId!,
          name: _name.text.trim(),
          description: _description.text.trim(),
          durationMinutes: int.parse(_duration.text.trim()),
          price: double.parse(_price.text.trim()),
          category: _category,
        );
      } else {
        await repo.createService(
          name: _name.text.trim(),
          description: _description.text.trim(),
          durationMinutes: int.parse(_duration.text.trim()),
          price: double.parse(_price.text.trim()),
          category: _category,
        );
      }
      ref.invalidate(vendorSalonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not save the service. $e';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text(
            '"${_name.text}" will disappear from your menu. Existing '
            'bookings keep their receipt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(vendorRepositoryProvider).deleteService(widget.serviceId!);
      ref.invalidate(vendorSalonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not delete the service. $e';
      });
    }
  }

  String? _validateDuration(String? value) {
    final v = int.tryParse(value?.trim() ?? '');
    if (v == null) return 'Enter the duration in minutes';
    if (v < 5) return 'At least 5 minutes';
    return null;
  }

  String? _validatePrice(String? value) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null) return 'Enter a price';
    if (v < 0) return 'The price cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_prefilled) {
      // The service list is already loaded when the editor opens from it.
      final salon = ref.watch(vendorSalonProvider).valueOrNull;
      final service =
          salon?.services.where((s) => s.id == widget.serviceId).firstOrNull;
      if (service == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit service')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      _prefill(service);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit service' : 'Add service'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete service',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _submitting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AuthTextField(
                label: 'Name',
                controller: _name,
                hint: 'e.g. Skin fade',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Give the service a name'
                    : null,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Description',
                controller: _description,
                hint: 'What does it include?',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Describe the service'
                    : null,
              ),
              const SizedBox(height: 18),
              const Text(
                'Category',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ServiceCategory>(
                initialValue: _category,
                items: [
                  for (final category in ServiceCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text('${category.emoji}  ${category.label}'),
                    ),
                ],
                onChanged: (category) =>
                    setState(() => _category = category ?? _category),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'Duration (min)',
                      controller: _duration,
                      hint: '45',
                      keyboardType: TextInputType.number,
                      validator: _validateDuration,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AuthTextField(
                      label: r'Price ($)',
                      controller: _price,
                      hint: '35',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      validator: _validatePrice,
                    ),
                  ),
                ],
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
                    : Text(_isEditing ? 'Save changes' : 'Add service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
