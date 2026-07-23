import 'package:flutter/material.dart';
import 'package:tracelet/tracelet.dart' as tl;
import '../services/geofence_api_service.dart';
import '../services/geofence_event_handler.dart';

class GeofenceSimulationScreen extends StatefulWidget {
  final GeofenceApiService apiService;
  final GeofenceEventHandler eventHandler;

  const GeofenceSimulationScreen({
    super.key,
    required this.apiService,
    required this.eventHandler,
  });

  @override
  State<GeofenceSimulationScreen> createState() => _GeofenceSimulationScreenState();
}

class _GeofenceSimulationScreenState extends State<GeofenceSimulationScreen> {
  List<tl.Geofence> _registeredGeofences = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  Future<void> _loadGeofences() async {
    setState(() => _isLoading = true);
    try {
      final geofences = await tl.Tracelet.getGeofences();
      setState(() => _registeredGeofences = geofences);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading geofences: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Geofence Simulator'),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGeofences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Simulate Event'),
                const SizedBox(height: 12),
                _buildSimulatorCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Active Geofences (${_registeredGeofences.length})'),
                const SizedBox(height: 12),
                if (_registeredGeofences.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No geofences registered in Tracelet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._registeredGeofences.map((g) => _buildGeofenceItem(g)),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSimulatorCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Manually trigger an ENTER event to test notifications and deep linking.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _simulateEnter('store_1', 'Reliance Digital'),
              icon: const Icon(Icons.login),
              label: const Text('Simulate ENTER (Store 1)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _simulateExit('store_1'),
              icon: const Icon(Icons.logout),
              label: const Text('Simulate EXIT (Store 1)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceItem(tl.Geofence geofence) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          geofence.identifier,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Lat: ${geofence.latitude}, Lng: ${geofence.longitude}\nRadius: ${geofence.radius}m',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.gps_fixed, color: Color(0xFFF5A623), size: 20),
      ),
    );
  }

  Future<void> _simulateEnter(String id, String name) async {
    // Manually call the event handler to test logic
    await widget.eventHandler.onGeofenceEnter(id, 0.0, 0.0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated ENTER for $name')),
    );
  }

  Future<void> _simulateExit(String id) async {
    await widget.eventHandler.onGeofenceExit(id, 0.0, 0.0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated EXIT for $id')),
    );
  }
}
