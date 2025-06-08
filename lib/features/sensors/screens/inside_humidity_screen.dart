import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart'; // Assuming TColors.mine is defined here

class InsideHumidityScreen extends StatefulWidget {
  const InsideHumidityScreen({super.key});

  @override
  State<InsideHumidityScreen> createState() => _InsideHumidityScreenState();
}

class _InsideHumidityScreenState extends State<InsideHumidityScreen> {
  // Firebase references updated for humidity
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensors/insideHumidity');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for humidity
  double? humidity;
  String? timestamp;
  String? selectedDate;
  Map<String, dynamic> hourlyData = {};

  @override
  void initState() {
    super.initState();
    _listenToHumidityData(); // Renamed from _listenToRealtimeBrightness
  }

  void _listenToHumidityData() {
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final double? newHumidity = double.tryParse(data['value'].toString());
        final newTimestamp = data['timestamp'];

        if (mounted) { // Good practice to check if widget is still in tree
          setState(() {
            humidity = newHumidity;
            timestamp = newTimestamp;
          });
        }

        _storeDataByDateAndHour(data);
      }
    });
  }

  void _storeDataByDateAndHour(Map data) {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final hourKey = DateFormat('HH:mm').format(now); // Stores data by minute

    _firestore
        .collection('insideHumidity') // Changed collection name
        .doc(dateKey)
        .collection('hours')
        .doc(hourKey)
        .set({
      'value': data['value'], // Storing the raw value from RTDB
      'timestamp': FieldValue.serverTimestamp(),
    }).catchError((error) {
      // Optional: Add error handling for Firestore writes
      debugPrint("Error storing humidity data: $error");
    });
  }

  Future<void> _pickDateAndLoadHourlyData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024), // Consider making this dynamic or configurable
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(picked);
      if (mounted) {
        setState(() {
          selectedDate = dateKey;
          hourlyData.clear();
          // Potentially show a loading indicator here
        });
      }

      try {
        final snapshot = await _firestore
            .collection('insideHumidity') // Changed collection name
            .doc(dateKey)
            .collection('hours')
            .get();

        if (mounted) {
          if (snapshot.docs.isNotEmpty) {
            Map<String, dynamic> dataMap = {};
            for (var doc in snapshot.docs) {
              dataMap[doc.id] = doc.data()['value'];
            }
            setState(() {
              hourlyData = dataMap;
            });
          } else {
            setState(() {
              hourlyData.clear(); // Ensure it's empty if no docs found
            });
          }
        }
      } catch (error) {
        // Optional: Add error handling for Firestore reads
        debugPrint("Error loading hourly humidity data: $error");
        if (mounted) {
          setState(() {
            hourlyData.clear();
            // Optionally, show an error message to the user
          });
        }
      }
      // Hide loading indicator here
    }
  }
  String _getHumidityComment(double? value) {
    if (value == null) return "";
    if (value < 30) {
      return "💧 Too dry - Plants may wilt. Consider misting or activating the humidifier.";
    } else if (value < 60) {
      return "🌬️ Optimal - Suitable humidity for most greenhouse plants.";
    } else {
      return "☔ High humidity - Risk of mold or fungal issues. Ensure proper ventilation.";
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
            // *** FIXED ICON HERE ***
            const Icon(Icons.water_drop, size: 60, color: Colors.blueAccent), // Changed to water_drop and a thematic color
            const SizedBox(height: 10),
            Text(
              humidity != null ? '${humidity!.toStringAsFixed(1)} %' : '--', // Unit changed to %
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Humidity', // Label changed
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            if (humidity != null)
              Text(
                _getHumidityComment(humidity), // Uses humidity-specific comment
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
    // This widget is identical to BrightnessScreen's, which is fine.
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
        onPressed: _pickDateAndLoadHourlyData,
      ),
    );
  }

  Widget _buildHourlyList() {
    if (selectedDate == null) return const SizedBox();

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
          // This formatting is good for consistency and handling potential non-numeric strings
          final formattedValue = double.tryParse(value.toString())?.toStringAsFixed(1) ?? 'N/A';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.indigo), // Consistent icon
              title: Text('Hour: $hour'),
              trailing: Text(
                '$formattedValue %', // Unit changed to %
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
      backgroundColor: const Color(0xFFF4F7FA), // Consistent background
      appBar: AppBar(
        title: const Text('Inside Humidity Monitor'), // Title changed
        centerTitle: true,
        backgroundColor: TColors.mine, // Consistent AppBar color
        elevation: 2,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildLiveCard(),
          _buildDateSelector(),
          const SizedBox(height: 10),
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Data for $selectedDate',
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