import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart'; // Assuming TColors.mine is defined here

class InsideTemperatureScreen extends StatefulWidget {
  const InsideTemperatureScreen({super.key});

  @override
  State<InsideTemperatureScreen> createState() => _InsideTemperatureScreenState();
}

class _InsideTemperatureScreenState extends State<InsideTemperatureScreen> {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensors/insideTemperature');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables aligned with the common pattern
  double? temperature; // Current temperature
  String? rtdbTimestamp; // Timestamp from RTDB for the current reading
  String? selectedDate; // For displaying which date's historical data is shown (YYYY-MM-DD)
  Map<String, dynamic> hourlyData = {}; // Stores historical data for the selectedDate

  @override
  void initState() {
    super.initState();
    _listenToTemperatureData();
    // Historical data will now be loaded on demand via _pickDateAndLoadHourlyData
  }

  void _listenToTemperatureData() {
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final double? newTemperature = double.tryParse(data['value'].toString());
        final newRtdbTimestamp = data['timestamp']?.toString();

        if (mounted) {
          setState(() {
            temperature = newTemperature;
            rtdbTimestamp = newRtdbTimestamp;
          });
        }
        // Pass the whole data map for consistency, even if only 'value' is used directly
        _storeDataByDateAndHour({'value': newTemperature, 'timestamp': newRtdbTimestamp});
      }
    }, onError: (error) {
      debugPrint("Error listening to temperature data: $error");
      // Handle error, e.g., show a snackbar or set an error state
    });
  }

  void _storeDataByDateAndHour(Map<String, dynamic> data) {
    final double? tempValue = data['value'] as double?;
    if (tempValue == null) return;

    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final hourKey = DateFormat('HH:mm').format(now); // Stores data by minute

    _firestore
        .collection('insideTemperature') // Collection for temperature
        .doc(dateKey)
        .collection('hours') // Subcollection for hourly (minute-by-minute) readings
        .doc(hourKey) // Document ID is the hour and minute
        .set({
      'value': tempValue, // Store the numeric temperature value
      'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp for this entry
    }).catchError((error) {
      debugPrint("Error storing temperature data: $error");
    });
  }

  Future<void> _pickDateAndLoadHourlyData() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate != null ? DateFormat('yyyy-MM-dd').parse(selectedDate!) : DateTime.now(),
      firstDate: DateTime(2024), // Consider making this dynamic
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(pickedDate);
      if (mounted) {
        setState(() {
          selectedDate = dateKey;
          hourlyData.clear(); // Clear previous data
          // You could show a loading indicator here
        });
      }

      try {
        final snapshot = await _firestore
            .collection('insideTemperature')
            .doc(dateKey)
            .collection('hours') // Fetch from the 'hours' subcollection
            .orderBy(FieldPath.documentId) // Sort by HH:MM
            .get();

        if (mounted) {
          if (snapshot.docs.isNotEmpty) {
            Map<String, dynamic> dataMap = {};
            for (var doc in snapshot.docs) {
              // doc.id is the HH:MM string
              dataMap[doc.id] = doc.data()['value'];
            }
            setState(() {
              hourlyData = dataMap;
            });
          } else {
            // No data for this date, hourlyData remains empty
            setState(() {
              // hourlyData is already cleared, so just ensure UI updates if needed
            });
          }
        }
      } catch (error) {
        debugPrint("Error loading hourly temperature data: $error");
        if (mounted) {
          setState(() {
            hourlyData.clear(); // Clear data on error
            // Optionally show an error message
          });
        }
      }
      // Hide loading indicator here
    }
  }
  String _getTemperatureAdvice(double? temp) {
    if (temp == null) return '🌡️ Waiting for temperature data...';
    if (temp < 18) {
      return '❄️ Too cold - Activate heaters to protect cold-sensitive plants.';
    } else if (temp <= 26) {
      return '🌿 Optimal - Ideal temperature range for most crops.';
    } else if (temp <= 30) {
      return '☀️ Warm - Monitor and improve airflow to prevent heat stress.';
    } else {
      return '🔥 Too hot - Urgently ventilate and cool to avoid plant damage.';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.thermostat, size: 60, color: Colors.redAccent), // Consistent icon style
            const SizedBox(height: 10),
            Text(
              temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : '-- °C',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Temperature',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Text(
              _getTemperatureAdvice(temperature),
              style: const TextStyle(fontSize: 14, color: Colors.teal, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              rtdbTimestamp != null ? 'Updated: $rtdbTimestamp' : '',
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
          backgroundColor: TColors.mine, // Using your defined color
          foregroundColor: Colors.white,
        ),
        onPressed: _pickDateAndLoadHourlyData,
      ),
    );
  }

  Widget _buildHourlyList() {
    if (selectedDate == null) return const SizedBox.shrink();

    if (hourlyData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("No temperature data for selected date.", style: TextStyle(color: Colors.grey))),
      );
    }

    final sortedHours = hourlyData.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        itemCount: sortedHours.length,
        itemBuilder: (context, index) {
          final hour = sortedHours[index]; // This is the HH:MM string
          final value = hourlyData[hour];
          final formattedValue = (value as num?)?.toStringAsFixed(1) ?? 'N/A';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.orange), // Thematic color for time/temp
              title: Text('Time: $hour'),
              trailing: Text(
                '$formattedValue °C',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
        title: const Text('Inside Temperature Monitor'),
        centerTitle: true,
        backgroundColor: TColors.mine, // Using your defined color
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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