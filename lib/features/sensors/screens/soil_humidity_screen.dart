import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart'; // Assuming TColors.mine and TColors.primary are defined here

class SoilHumidityScreen extends StatefulWidget {
  const SoilHumidityScreen({super.key});

  @override
  State<SoilHumidityScreen> createState() => _SoilHumidityScreenState();
}

class _SoilHumidityScreenState extends State<SoilHumidityScreen> {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensors/soilHumidity');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables aligned with the common pattern
  double? soilHumidity;
  String? rtdbTimestamp; // Renamed from 'timestamp' for clarity
  String? selectedDate; // For displaying which date's historical data is shown (YYYY-MM-DD)
  Map<String, dynamic> hourlyData = {}; // Stores historical data for the selectedDate

  @override
  void initState() {
    super.initState();
    _listenToSoilHumidityData();
  }

  void _listenToSoilHumidityData() {
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final double? newSoilHumidity = double.tryParse(data['value'].toString());
        final newRtdbTimestamp = data['timestamp']?.toString();

        if (mounted) {
          setState(() {
            soilHumidity = newSoilHumidity;
            rtdbTimestamp = newRtdbTimestamp;
          });
        }
        _storeDataByDateAndHour({'value': newSoilHumidity, 'timestamp': newRtdbTimestamp});
      }
    }, onError: (error) {
      debugPrint("Error listening to soil humidity data: $error");
    });
  }

  void _storeDataByDateAndHour(Map<String, dynamic> data) {
    final double? humidityValue = data['value'] as double?;
    if (humidityValue == null) return;

    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final hourKey = DateFormat('HH:mm').format(now);

    _firestore
        .collection('soilHumidity') // Collection for soil humidity
        .doc(dateKey)
        .collection('hours')
        .doc(hourKey)
        .set({
      'value': humidityValue,
      'timestamp': FieldValue.serverTimestamp(),
    }).catchError((error) {
      debugPrint("Error storing soil humidity data: $error");
    });
  }

  Future<void> _pickDateAndLoadHourlyData() async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate != null ? DateFormat('yyyy-MM-dd').parse(selectedDate!) : DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        builder: (context, child) { // Optional: Apply theme to DatePicker
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: TColors.mine, // header background color
                onPrimary: Colors.white, // header text color
                onSurface: TColors.darkerGrey, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: TColors.mine, // button text color
                ),
              ),
            ),
            child: child!,
          );
        }
    );

    if (pickedDate != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(pickedDate);
      if (mounted) {
        setState(() {
          selectedDate = dateKey;
          hourlyData.clear();
        });
      }

      try {
        final snapshot = await _firestore
            .collection('soilHumidity')
            .doc(dateKey)
            .collection('hours')
            .orderBy(FieldPath.documentId)
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
              // hourlyData is already cleared
            });
          }
        }
      } catch (error) {
        debugPrint("Error loading hourly soil humidity data: $error");
        if (mounted) {
          setState(() {
            hourlyData.clear();
          });
        }
      }
    }
  }
  String _getSoilAdvice(double? humidity) {
    if (humidity == null) return '🌱 Waiting for soil moisture data...';
    if (humidity < 30) {
      return '💧 Soil too dry - Watering needed to prevent plant stress.';
    } else if (humidity < 70) {
      return '✅ Optimal moisture - Good condition for root development.';
    } else {
      return '💦 Soil too wet - Risk of root rot. Check drainage and reduce watering.';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.eco, size: 40, color: Colors.green), // Changed icon slightly
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Soil Moisture', // Changed title slightly
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: TColors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Soil Moisture Info'),
                        content: const Text(
                            'This value indicates the current moisture level of the soil. Keeping it optimal ensures healthy plant growth.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close', style: TextStyle(color: TColors.mine)),
                          ),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 20),
            Text(
              soilHumidity != null ? '${soilHumidity!.toStringAsFixed(1)}%' : '-- %',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: TColors.primary, // Using TColors.primary from original
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getSoilAdvice(soilHumidity),
              style: const TextStyle(fontSize: 14, color: TColors.darkGrey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
          backgroundColor: TColors.mine,
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
        child: Center(child: Text("No soil moisture data for selected date.", style: TextStyle(color: Colors.grey))),
      );
    }

    final sortedHours = hourlyData.keys.toList()..sort();

    return Expanded(
      child: ListView.builder(
        itemCount: sortedHours.length,
        itemBuilder: (context, index) {
          final hour = sortedHours[index];
          final value = hourlyData[hour];
          final formattedValue = (value as num?)?.toStringAsFixed(1) ?? 'N/A';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.opacity_rounded, color: Color(0xFF8B4513)), // Brown color for soil/moisture
              title: Text('Time: $hour'),
              trailing: Text(
                '$formattedValue %',
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
        title: const Text('Soil Moisture Monitor'), // Updated title slightly
        centerTitle: true,
        backgroundColor: TColors.mine,
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