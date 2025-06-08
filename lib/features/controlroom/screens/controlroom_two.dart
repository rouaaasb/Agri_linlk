import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

import '../../../utils/constants/colors.dart';
import '../../home/screens/home_screenn.dart';
import '../../home/screens/settings_screen.dart';

class ControlRoomTwo extends StatefulWidget {
  const ControlRoomTwo({super.key});

  @override
  State<ControlRoomTwo> createState() => _ControlRoomTwoState();
}

class _ControlRoomTwoState extends State<ControlRoomTwo> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool isAutoMode = true;

  double doorPosition = 0;
  String doorStatus = 'Closed';

  double windowPosition = 0;
  String windowStatus = 'Closed';

  bool ledOn = false;
  String ledStatus = 'Off';

  bool fanOn = false;
  String fanStatus = 'Off';

  bool irrigationOn = false;
  String irrigationStatus = 'Off';

  // Sensor Data
  double currentTemperature = 0.0;
  double currentHumidity = 0.0;
  double currentSoilMoisture = 0.0;
  double currentLightIntensity = 0.0;
  double currentAirQuality = 0.0;
  double currentWaterLevel = 0.0; //  water level
  String? waterLevelTimestamp; //       water level

  // Tank max value for percentage calculation
  final double maxWaterLevel = 100.0; //  Adjust this to your sensor's maximum
  // Threshold values from database
  double _tempThresholdHigh = 30.0;
  double _tempThresholdLow = 25.0;
  double _soilMoistureThresholdLow = 30.0;
  double _soilMoistureThresholdHigh = 70.0;
  double _lightIntensityThresholdLow = 400.0;
  double _lightIntensityThresholdHigh = 700.0;
  double _doorOpenTemperature = 35.0;
  double _waterLevelThresholdLow = 20.0; // added water level threshold

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeListeners();
    _getThresholdValues(); // Fetch thresholds on init
  }

  // Initialize the notification plugin
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings(
        'app_icon'); // Replace 'app_icon' with your app's notification icon.
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show a simple notification
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'manual_mode_alerts', // Change to a unique channel ID
      'Manual Mode Alerts', // Channel name
      channelDescription:
      'Alerts for when actuators might need adjustment in manual mode', // Channel description
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
    );
  }

  void _initializeListeners() {
    _dbRef.child("greenhouse/mode").onValue.listen((event) {
      final mode = event.snapshot.value;
      if (mode == "auto") {
        setState(() => isAutoMode = true);
      } else {
        setState(() => isAutoMode = false);
        _checkManualActuatorStatus(); // check when mode is changed to manual
      }
    });

    _dbRef.child("greenhouse/door").onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          doorPosition = (value as num).toDouble();
          doorStatus = _getPositionLabel(doorPosition);
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting door data: $error'); // Add error handling
    });

    _dbRef.child("greenhouse/window").onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          windowPosition = (value as num).toDouble();
          windowStatus = _getPositionLabel(windowPosition);
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting window data: $error');
    });

    _dbRef.child("greenhouse/led").onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          ledOn = value == 1;
          ledStatus = ledOn ? 'On' : 'Off';
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting led data: $error');
    });

    _dbRef.child("greenhouse/fan").onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          fanOn = value == 1;
          fanStatus = fanOn ? 'On' : 'Off';
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting fan data: $error');
    });

    _dbRef.child("greenhouse/irrigation").onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          irrigationOn = value == 1;
          irrigationStatus = irrigationOn ? 'On' : 'Off';
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting irrigation data: $error');
    });

    // Listen to sensor values.  Adjusted to match your database structure
    _dbRef.child("sensors/insideTemperature").onValue.listen((event) {
      // Changed path
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          currentTemperature = (value as num).toDouble();
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting temperature: $error');
    });

    _dbRef.child("sensors/insideHumidity").onValue.listen((event) {
      // Changed path
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          currentHumidity = (value as num).toDouble();
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting humidity: $error');
    });

    _dbRef.child("sensors/soilHumidity").onValue.listen((event) {
      // Changed path
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          currentSoilMoisture = (value as num).toDouble();
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting soil moisture: $error');
    });

    _dbRef.child("sensors/brightness").onValue.listen((event) {
      // Changed path
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          currentLightIntensity = (value as num).toDouble();
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting light intensity: $error');
    });

    _dbRef.child("sensors/air_quality").onValue.listen((event) {
      // Changed path
      final value = event.snapshot.value;
      if (value != null) {
        setState(() {
          currentAirQuality = (value as num).toDouble();
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting air quality: $error');
    });
    _dbRef.child("sensors/waterLevel").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final newValue = data['value'] as int?;
        final newTimestamp = data['timestamp'] as int?;
        setState(() {
          currentWaterLevel = newValue?.toDouble() ?? 0.0;
          waterLevelTimestamp =
          newTimestamp != null ? _formatTimestamp(newTimestamp) : null;
        });
        if (!isAutoMode) {
          _checkManualActuatorStatus();
        }
      }
    }, onError: (error) {
      print('Error getting water level data: $error');
    });
  }

  String? _formatTimestamp(int timestamp) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('HH:mm:ss').format(dateTime);
    } catch (e) {
      return null;
    }
  }

  void _getThresholdValues() {
    // Fetch temperature thresholds
    _dbRef.child('thresholds/temperature_high').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _tempThresholdHigh = (event.snapshot.value as num).toDouble();
        });
      }
    });
    _dbRef.child('thresholds/temperature_low').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _tempThresholdLow = (event.snapshot.value as num).toDouble();
        });
      }
    });

    // Fetch soil moisture thresholds
    _dbRef.child('thresholds/soil_moisture_low').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _soilMoistureThresholdLow = (event.snapshot.value as num).toDouble();
        });
      }
    });
    _dbRef.child('thresholds/soil_moisture_high').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _soilMoistureThresholdHigh = (event.snapshot.value as num).toDouble();
        });
      }
    });

    // Fetch light intensity thresholds
    _dbRef.child('thresholds/light_intensity_low').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _lightIntensityThresholdLow = (event.snapshot.value as num).toDouble();
        });
      }
    });

    _dbRef.child('thresholds/light_intensity_high').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _lightIntensityThresholdHigh = (event.snapshot.value as num).toDouble();
        });
      }
    });
    _dbRef.child('thresholds/door_open_temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _doorOpenTemperature = (event.snapshot.value as num).toDouble();
        });
      }
    });
    //get water level threshold
    _dbRef.child('thresholds/water_level_low').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _waterLevelThresholdLow = (event.snapshot.value as num).toDouble();
        });
      }
    });
  }

  void _checkManualActuatorStatus() {
    if (!isAutoMode) {
      // Check fan and temperature
      if (currentTemperature > _tempThresholdHigh && !fanOn) {
        _showNotification(
            'High Temperature Alert', 'Consider turning the fan ON. Temperature is ${currentTemperature.toStringAsFixed(1000)}°C');
      } else if (currentTemperature <= _tempThresholdLow && fanOn) {
        _showNotification(
            'Temperature Normal', 'Consider turning the fan OFF. Temperature is ${currentTemperature.toStringAsFixed(1000)}°C');
      } else if (currentTemperature <= _tempThresholdHigh && !fanOn) {
        // do nothing
      } else if (currentTemperature > _tempThresholdLow && fanOn) {
        //do nothing
      }

      // Check irrigation and soil moisture
      if (currentSoilMoisture < _soilMoistureThresholdLow && !irrigationOn) {
        _showNotification('Low Soil Moisture',
            'Consider turning ON irrigation. Soil moisture is ${currentSoilMoisture.toStringAsFixed(1000)}%');
      } else if (currentSoilMoisture > _soilMoistureThresholdHigh &&
          irrigationOn) {
        _showNotification('High Soil Moisture',
            'Consider turning OFF irrigation. Soil moisture is ${currentSoilMoisture.toStringAsFixed(1000)}%');
      } else if (currentSoilMoisture >= _soilMoistureThresholdLow &&
          !irrigationOn) {
        //do nothing
      } else if (currentSoilMoisture <= _soilMoistureThresholdHigh &&
          irrigationOn) {
        //do nothing
      }

      // Check LED and light intensity
      if (currentLightIntensity < _lightIntensityThresholdLow && !ledOn) {
        _showNotification(
            'Low Light Intensity', 'Consider turning ON the LED. Light intensity is ${currentLightIntensity.toStringAsFixed(8000)} Lux');
      } else if (currentLightIntensity > _lightIntensityThresholdHigh && ledOn) {
        _showNotification(
            'High Light Intensity', 'Consider turning OFF the LED. Light intensity is ${currentLightIntensity.toStringAsFixed(8000)} Lux');
      } else if (currentLightIntensity >= _lightIntensityThresholdLow &&
          !ledOn) {
        //do nothing
      } else if (currentLightIntensity <= _lightIntensityThresholdHigh && ledOn) {
        //do nothing
      }

      // Check door and temperature
      if (currentTemperature > _doorOpenTemperature && doorPosition == 0) {
        _showNotification('High Temperature Alert',
            'Consider opening the door. Temperature is ${currentTemperature.toStringAsFixed(100)}°C');
      }

      // Check water level
      if (currentWaterLevel < _waterLevelThresholdLow) {
        _showNotification('Low Water Level',
            'Water level is critically low: ${currentWaterLevel.toStringAsFixed(0)}%');
      }
    }
  }

  void _toggleAutoMode(bool value) {
    setState(() {
      isAutoMode = value;
    });
    _dbRef.child("greenhouse/mode").set(value ? "auto" : "manual");
  }

  void _updateDoorPosition(double value) {
    setState(() {
      doorPosition = value.roundToDouble();
      doorStatus = _getPositionLabel(doorPosition);
    });
    _dbRef.child("greenhouse/door").set(value.toInt());
    if (!isAutoMode) {
      _checkManualActuatorStatus();
    }
  }

  void _updateWindowPosition(double value) {
    setState(() {
      windowPosition = value.roundToDouble();
      windowStatus = _getPositionLabel(windowPosition);
    });
    _dbRef.child("greenhouse/window").set(value.toInt());
    if (!isAutoMode) {
      _checkManualActuatorStatus();
    }
  }

  String _getPositionLabel(double value) {
    if (value == 0) return 'Closed';
    if (value == 25) return 'Quarter Open';
    if (value == 50) return 'Half Open';
    if (value == 75) return 'Three Quarters Open';
    return 'Fully Open';
  }

  void _toggleLed(bool value) {
    setState(() {
      ledOn = value;
      ledStatus = value ? 'On' : 'Off';
    });
    _dbRef.child("greenhouse/led").set(value ? 1 : 0);
    if (!isAutoMode) {
      _checkManualActuatorStatus();
    }
  }

  void _toggleFan(bool value) {
    setState(() {
      fanOn = value;
      fanStatus = value ? 'On' : 'Off';
    });
    _dbRef.child("greenhouse/fan").set(value ? 1 : 0);
    if (!isAutoMode) {
      _checkManualActuatorStatus();
    }
  }

  void _toggleIrrigation(bool value) {
    setState(() {
      irrigationOn = value;
      irrigationStatus = value ? 'On' : 'Off';
    });
    _dbRef.child("greenhouse/irrigation").set(value ? 1 : 0);
    if (!isAutoMode) {
      _checkManualActuatorStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Room'),
        centerTitle: true,
        backgroundColor: TColors.mine,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            /// Mode Display
            Center(
              child: Text(
                isAutoMode ? "Mode: Automatic" : "Mode: Manual",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            /// Auto Mode Switch
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_remote),
                title: const Text("Automatic Mode"),
                trailing: Switch(
                  value: isAutoMode,
                  onChanged: _toggleAutoMode,
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Door Control
            _buildSliderControl(
              icon: Icons.door_front_door,
              title: "Door Control",
              status: doorStatus,
              value: doorPosition,
              onChanged: !isAutoMode ? _updateDoorPosition : null,
            ),

            /// Window Control
            _buildSliderControl(
              icon: Icons.window,
              title: "Window Control",
              status: windowStatus,
              value: windowPosition,
              onChanged: !isAutoMode ? _updateWindowPosition : null,
            ),

            /// LED Control
            _buildSwitchControl(
              icon: Icons.lightbulb,
              title: "LED Control",
              status: ledStatus,
              value: ledOn,
              onChanged: !isAutoMode ? _toggleLed : null,
            ),

            /// Fan Control
            _buildSwitchControl(
              icon: Icons.air,
              title: "Fan Control",
              status: fanStatus,
              value: fanOn,
              onChanged: !isAutoMode ? _toggleFan : null,
            ),

            /// Irrigation Control
            _buildSwitchControl(
              icon: Icons.grass,
              title: "Irrigation Control",
              status: irrigationStatus,
              value: irrigationOn,
              onChanged: !isAutoMode ? _toggleIrrigation : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainNavBar(currentIndex: 1),
    );
  }

  Widget _buildSliderControl({
    required IconData icon,
    required String title,
    required String status,
    required double value,
    required ValueChanged<double>? onChanged,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: $status"),
            Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 4,
              label: '${value.round()}%',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchControl({
    required IconData icon,
    required String title,
    required String status,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 36),
        title: Text(title),
        subtitle: Text("Status: $status"),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class MainNavBar extends StatelessWidget {
  final int currentIndex;
  const MainNavBar({required this.currentIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()));
            break;
          case 1:
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ControlRoomTwo()));
            break;
          case 2:
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
      ],
      selectedItemColor: TColors.mine,
      unselectedItemColor: Colors.black38,
      backgroundColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 12,
    );
  }
}

