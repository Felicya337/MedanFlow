import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medan Flow - Driver"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Consumer<TrackingProvider>(
              builder: (context, tracking, child) {
                return Column(
                  children: [
                    Text(
                      tracking.isTracking 
                        ? "Status: Sedang Narik (On Duty)" 
                        : "Status: Off Duty",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: tracking.isTracking ? Colors.green : Colors.red
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => tracking.toggleTracking(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: tracking.isTracking ? Colors.red : Colors.green,
                      ),
                      child: Text(
                        tracking.isTracking ? "BERHENTI NARIK" : "MULAI NARIK",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}