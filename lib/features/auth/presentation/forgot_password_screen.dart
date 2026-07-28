import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../data/api/api_client.dart';
import 'auth_validators.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_text_field.dart';

/// Two steps on one screen: request a reset code for an email, then enter
/// the code with a new password. On success the owner lands back on the
/// login screen to sign in with the new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = ref.read(vendorAuthRepositoryProvider);
      if (!_codeSent) {
        await auth.requestPasswordReset(_email.text.trim());
        setState(() => _codeSent = true);
      } else {
        await auth.resetPassword(
          email: _email.text.trim(),
          code: _code.text.trim(),
          newPassword: _password.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Password updated — sign in with your new one')));
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach BeautyHub. Check your connection.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Reset your password',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent
                  ? 'If ${_email.text.trim()} has an account, a 6-digit '
                      'code is on its way'
                  : "Enter your account's email and we'll send a reset code",
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Email',
                    controller: _email,
                    hint: 'owner@yoursalon.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                    textInputAction:
                        _codeSent ? TextInputAction.next : TextInputAction.done,
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Reset code',
                      controller: _code,
                      hint: '6-digit code',
                      keyboardType: TextInputType.number,
                      validator: validateResetCode,
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'New password',
                      controller: _password,
                      hint: 'At least 8 characters',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: validateNewPassword,
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_codeSent ? 'Reset password' : 'Send reset code'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _submitting ? null : _resendCode,
                  child: const Text('Send a new code'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Re-request a code for the (possibly corrected) email.
  void _resendCode() {
    setState(() => _codeSent = false);
    _submit();
  }
}
