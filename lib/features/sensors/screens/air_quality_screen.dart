import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../utils/constants/colors.dart';

class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({super.key});

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensors/air_quality');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double? airQuality;
  String? timestamp;
  String? selectedDate;
  Map<String, dynamic> hourlyData = {};

  @override
  void initState() {
    super.initState();
    _listenToRealtimeAirQuality();
  }

  void _listenToRealtimeAirQuality() {
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final double? newAirQuality = double.tryParse(data['value'].toString());
        final newTimestamp = data['timestamp'];

        setState(() {
          airQuality = newAirQuality;
          timestamp = newTimestamp;
        });

        _storeDataByDateAndHour(data);
      }
    });
  }

  void _storeDataByDateAndHour(Map data) {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final hourKey = DateFormat('HH:mm').format(now);

    _firestore
        .collection('air_quality')
        .doc(dateKey)
        .collection('hours')
        .doc(hourKey)
        .set({
      'value': data['value'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _pickDateAndLoadHourlyData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        selectedDate = dateKey;
        hourlyData.clear();
      });

      final snapshot = await _firestore
          .collection('air_quality')
          .doc(dateKey)
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
  }

  String _getAirQualityComment(double? value) {
    if (value == null) return "";
    if (value > 200) {
      return "🚨 Very poor - Ventilation required! Air quality may harm plant health.";
    } else if (value > 150) {
      return "⚠️ Poor - Consider increasing ventilation or filtering the air.";
    } else if (value > 100) {
      return "🌤️ Moderate - Acceptable, but sensitive plants might be affected.";
    } else {
      return "🌱 Good - Optimal air quality for healthy plant growth.";
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
            const Icon(Icons.air, size: 60, color: Colors.amber),
            const SizedBox(height: 10),
            Text(
              airQuality != null ? '${airQuality!.toStringAsFixed(1)} µg/m³' : '--',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Air Quality',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            if (airQuality != null)
              Text(
                _getAirQualityComment(airQuality),
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
          final formattedValue = double.tryParse(value.toString())?.toStringAsFixed(1) ?? value.toString();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.indigo),
              title: Text('Hour: $hour'),
              trailing: Text(
                '$formattedValue µg/m³',
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
        title: const Text('Air Quality Monitor'),
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