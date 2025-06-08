import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants/colors.dart';

class SoilTempScreen extends StatefulWidget {
  const SoilTempScreen({super.key});

  @override
  State<SoilTempScreen> createState() => _SoilTempScreenState();
}

class _SoilTempScreenState extends State<SoilTempScreen> {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensors/soilTemperature');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  double? temperature;
  String? timestamp;
  DateTime? _selectedDate;
  double? historicalTemp;
  String? historicalTimestamp;
  Map<String, dynamic> hourlyData = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenToSoilTempData();
    _selectedDate = DateTime.now();
    _fetchHourlyData(_selectedDate!);
  }

  void _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'soil_temp_channel',
      'Soil Temperature Alerts',
      description: 'Notifications when soil temperature is too high',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _listenToSoilTempData() {
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final newTemp = double.tryParse(data['value'].toString());
        final newTimestamp = data['timestamp'];

        setState(() {
          temperature = newTemp;
          timestamp = newTimestamp;
        });

        _storeDataByDateAndHour(newTemp);
        if (newTemp != null && newTemp > 35) {
          _showHighTempNotification(newTemp);
        }
      }
    });
  }

  void _storeDataByDateAndHour(double? value) {
    if (value == null) return;

    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final hourKey = DateFormat('HH:mm').format(now);

    _firestore
        .collection('soilTemperature')
        .doc(dateKey)
        .collection('hours')
        .doc(hourKey)
        .set({
      'value': value,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showHighTempNotification(double temp) async {
    const androidDetails = AndroidNotificationDetails(
      'soil_temp_channel',
      'Soil Temperature Alerts',
      channelDescription: 'Alerts for abnormal soil temperature',
      importance: Importance.high,
      priority: Priority.high,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'High Soil Temperature!',
      'Current temperature is ${temp.toStringAsFixed(1)} °C',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _fetchHourlyData(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      hourlyData.clear();
    });

    final snapshot = await _firestore
        .collection('soilTemperature')
        .doc(formattedDate)
        .collection('hours')
        .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, dynamic> dataMap = {};
      for (var doc in snapshot.docs) {
        dataMap[doc.id] = doc.data()['value'];
      }
      setState(() {
        hourlyData = dataMap;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        hourlyData.clear();
      });
      _fetchHourlyData(picked);
    }
  }

  String _getTemperatureAdvice() {
    if (temperature == null) return '🌡️ Waiting for soil temperature data...';

    if (temperature! > 35) {
      return '🔥 Soil temperature too high! Use shading or watering to cool it down.';
    } else if (temperature! < 10) {
      return '❄️ Soil temperature too low! Consider soil heating or greenhouse insulation.';
    } else {
      return '✅ Soil temperature is optimal. Maintain current conditions and monitor regularly.';
    }
  }


  Widget _buildLiveCard() {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.thermostat, size: 60, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(
              temperature != null ? '${temperature!.toStringAsFixed(1)} °C' : '--',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Temperature',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            if (temperature != null)
              Text(
                _getTemperatureAdvice(),
                style: const TextStyle(fontSize: 14, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 6),
            Text(
              timestamp != null ? 'Updated: $timestamp' : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: const Text('Select a Date'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: TColors.mine,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _selectDate(context),
      ),
    );
  }

  Widget _buildHourlyList() {
    if (_selectedDate == null) return const SizedBox();

    if (hourlyData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No data for selected date.", style: TextStyle(color: Colors.grey)),
      );
    }

    final sortedHours = hourlyData.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        itemCount: sortedHours.length,
        itemBuilder: (context, index) {
          final hour = sortedHours[index];
          final value = hourlyData[hour];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.thermostat_outlined, color: Colors.redAccent),
              title: Text('Hour: $hour'),
              trailing: Text(
                '${value?.toStringAsFixed(1)} °C',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Soil Temperature Monitor"),
        backgroundColor: TColors.mine,
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildLiveCard(),
          _buildDateSelector(),
          const SizedBox(height: 10),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Data for ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          _buildHourlyList(),
        ],
      ),
    );
  }
}