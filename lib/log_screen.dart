import 'package:flutter/material.dart';

class GeofenceEvent {
  final DateTime enterTime;
  final DateTime? exitTime;
  final Duration? duration;

  GeofenceEvent({required this.enterTime, this.exitTime, this.duration});
}

class LogScreen extends StatelessWidget {
  final List<GeofenceEvent> events;

  const LogScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: const Text('Geofence Log'),toolbarHeight: 80,),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text('Entered at: ${event.enterTime}'),
            subtitle: event.exitTime != null
                ? Text('Exited at: ${event.exitTime}, Duration: ${event.duration}')
                : const Text('Inside geofence'),
          );
        },
      ),
    );
  }
}
