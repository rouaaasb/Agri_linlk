import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants/colors.dart';

class WaterLevelScreen extends StatefulWidget {
  const WaterLevelScreen({super.key});

  @override
  State<WaterLevelScreen> createState() => _WaterLevelScreenState();
}

class _WaterLevelScreenState extends State<WaterLevelScreen> {
  final DatabaseReference _waterLevelRef = FirebaseDatabase.instance.ref('sensors/waterLevel');
  double? _currentValue;
  String? _timestamp;
  bool _isLoading = true;

  // Tank max value (adjust based on your sensor's max reading)
  final double maxValue = 100.0;
  final double tankHeight = 200.0; // Visual height of the tank

  @override
  void initState() {
    super.initState();
    _listenToWaterLevelData();
  }

  void _listenToWaterLevelData() {
    _waterLevelRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final newValue = data['value'] as int?;
        final newTimestamp = data['timestamp'] as int?;

        setState(() {
          _currentValue = newValue?.toDouble();
          _timestamp = newTimestamp != null ? _formatTimestamp(newTimestamp) : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Error listening to water level data: $error');
      setState(() {
        _isLoading = false;
      });
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

  double _calculateFillPercentage() {
    if (_currentValue == null || maxValue == 0) {
      return 0;
    }
    return (_currentValue! / maxValue).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillPercentage = _calculateFillPercentage();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Water Level Monitor", style: TextStyle(color: Colors.white)),
        backgroundColor: TColors.mine,
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 120,
                    height: tankHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey[200]!, Colors.grey[300]!],
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: 120,
                    height: tankHeight * fillPercentage,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blueAccent, Colors.blue],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: Icon(Icons.water_drop, size: 30, color: Colors.blueAccent.withOpacity(0.7)),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Text(
                      '${(_currentValue ?? 0).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Last Updated', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timestamp != null ? _timestamp! : 'N/A',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}