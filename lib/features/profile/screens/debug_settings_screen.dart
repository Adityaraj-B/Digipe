import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/auth_bloc.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hard check to prevent this screen from being useful in release
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Debug only')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Auth Override', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Paste a valid DigiPe JWT token to skip OTP login.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                hintText: 'Paste JWT Token',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final token = _tokenController.text.trim();
                  if (token.isNotEmpty) {
                    context.read<AuthBloc>().add(AuthSetDevToken(token));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dev token applied successfully')),
                    );
                  }
                },
                child: const Text('Apply Token'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'WARNING: This bypasses all client-side auth. The backend will still validate the token.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
