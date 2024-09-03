import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'log_screen.dart'; // Import the log screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF603F83), // Royal Purple
        scaffoldBackgroundColor: Color(0xFFC7D3D4), // Ice Flow
        textTheme: TextTheme(
          titleLarge: TextStyle(color: Color(0xFF603F83), fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Color(0xFF603F83),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF603F83), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey, width: 1),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  FlutterLocalNotificationsPlugin? _localNotifications;
  StreamSubscription<Position>? _positionStream;
  List<GeofenceEvent> _geofenceLog = [];
  DateTime? _enterTime;
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);
    _localNotifications!.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel', // id
      'Geofence', // name
      channelDescription: 'Notifications for geofencing', // description
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _localNotifications!.show(0, title, body, platformDetails);
  }

  void _startTracking() {
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      _showError("Please enter both latitude and longitude.");
      return;
    }

    double targetLat = double.parse(_latitudeController.text);
    double targetLng = double.parse(_longitudeController.text);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1),
    ).listen((Position position) async {
      double distance = Geolocator.distanceBetween(position.latitude, position.longitude, targetLat, targetLng);
      setState(() {
        _distance = distance;
      });

      if (distance <= 10) {
        if (_enterTime == null) {
          _enterTime = DateTime.now();
          _showNotification("Geofence Alert", "You have entered the geofence area.");
        }
      } else {
        if (_enterTime != null) {
          DateTime exitTime = DateTime.now();
          Duration timeSpent = exitTime.difference(_enterTime!);
          _geofenceLog.add(GeofenceEvent(enterTime: _enterTime!, exitTime: exitTime, duration: timeSpent));
          _enterTime = null;
          _showNotification("Geofence Alert", "You have exited the geofence area.");
        }
      }
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text('Geofence Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogScreen(events: _geofenceLog)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _latitudeController,
              decoration: InputDecoration(
                labelText: "Enter Latitude",
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF603F83)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _longitudeController,
              decoration: InputDecoration(
                labelText: "Enter Longitude",
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF603F83)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _startTracking,
                child: Text("Start Tracking"),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                "Distance to Target: ${_distance.toStringAsFixed(2)} meters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF603F83),
                ),
              ),
            ),
            Spacer(), // Adjust the space at the bottom
          ],
        ),
      ),
    );
  }
}
