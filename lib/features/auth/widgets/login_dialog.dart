import 'package:focusable_control_builder/focusable_control_builder.dart';
import 'package:lumio/services/auth_service.dart';
import 'package:lumio/services/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = getIt<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegistering) {
        await authService.registerWithEmailAndPassword(email, password);
      } else {
        await authService.signInWithEmailAndPassword(email, password);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Authentication failed';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isRegistering ? 'Create Account' : 'Sign In'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (_isRegistering && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isRegistering
                      ? 'Already have an account?'
                      : 'Don\'t have an account?'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _errorMessage = null;
                      });
                    },
                    child: Text(_isRegistering ? 'Sign In' : 'Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FocusableControlBuilder(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          builder: (context, state) {
            final isFocused = state.isFocused;
            return TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                backgroundColor: isFocused ? Colors.white.withOpacity(0.1) : null,
                foregroundColor: isFocused ? Colors.white : null,
              ),
              child: const Text('Cancel'),
            );
          },
        ),
        FocusableControlBuilder(
          onPressed: _isLoading ? null : _submit,
          builder: (context, state) {
            final isFocused = state.isFocused;
            return ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFocused
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: isFocused
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onPrimary,
                side: isFocused
                    ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
                elevation: isFocused ? 4 : 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isRegistering ? 'Register' : 'Sign In'),
            );
          },
        ),
      ],
    );
  }
}
