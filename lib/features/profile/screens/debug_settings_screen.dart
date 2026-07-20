import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/screens/bloc/auth_bloc.dart';
import '../../geofencing/services/geofence_api_service.dart';
import '../../geofencing/services/geofence_event_handler.dart';
import '../../geofencing/screens/geofence_simulation_screen.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(24.0),
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
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          const Text('Geofencing Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Manually test geofence events and view registration state.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeofenceSimulationScreen(
                      apiService: context.read<GeofenceApiService>(),
                      eventHandler: context.read<GeofenceEventHandler>(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Open Geofence Simulator'),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'WARNING: These tools bypass standard app flows for testing purposes.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
