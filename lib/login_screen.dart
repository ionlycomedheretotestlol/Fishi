import 'package:flutter/material.dart';

import 'main.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onDone});

  final void Function(Map<String, dynamic> profile) onDone;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _name.text.trim();
    if (username.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var user = supabase.auth.currentUser;
      user ??= (await supabase.auth.signInAnonymously()).user;
      final profile = await supabase
          .from('profiles')
          .upsert({'id': user!.id, 'username': username})
          .select()
          .single();
      widget.onDone(profile);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Fishi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 32,
                    textInputAction: TextInputAction.go,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.panel,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.mine),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _name.text.trim().isEmpty || _busy ? 0.4 : 1,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mine,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_busy ? 'Joining' : 'Continue',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 14)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
