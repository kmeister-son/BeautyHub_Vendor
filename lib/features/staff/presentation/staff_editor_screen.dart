import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/staff_member.dart';
import '../../auth/presentation/widgets/auth_error_banner.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../../salon/presentation/providers/vendor_providers.dart';

/// Create/edit form for one team member. [staffId] null means "add new".
class StaffEditorScreen extends ConsumerStatefulWidget {
  const StaffEditorScreen({super.key, this.staffId});

  final String? staffId;

  @override
  ConsumerState<StaffEditorScreen> createState() => _StaffEditorScreenState();
}

class _StaffEditorScreenState extends ConsumerState<StaffEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();

  bool _prefilled = false;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.staffId != null;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _prefill(StaffMember member) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = member.name;
    _role.text = member.role;
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
        await repo.updateStaff(
          widget.staffId!,
          name: _name.text.trim(),
          role: _role.text.trim(),
        );
      } else {
        await repo.createStaff(
          name: _name.text.trim(),
          role: _role.text.trim(),
        );
      }
      ref.invalidate(vendorSalonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not save the team member. $e';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove team member?'),
        content: Text('${_name.text} will no longer be bookable. Existing '
            'bookings keep their receipt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep them'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
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
      await ref.read(vendorRepositoryProvider).deleteStaff(widget.staffId!);
      ref.invalidate(vendorSalonProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not remove the team member. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_prefilled) {
      // The team list is already loaded when the editor opens from it.
      final salon = ref.watch(vendorSalonProvider).valueOrNull;
      final member =
          salon?.staff.where((s) => s.id == widget.staffId).firstOrNull;
      if (member == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit team member')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      _prefill(member);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit team member' : 'Add team member'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Remove team member',
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
                label: 'Full name',
                controller: _name,
                hint: 'e.g. Amara Osei',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter their name'
                    : null,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Role',
                controller: _role,
                hint: 'e.g. Senior stylist',
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter their role'
                    : null,
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
                    : Text(_isEditing ? 'Save changes' : 'Add member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
