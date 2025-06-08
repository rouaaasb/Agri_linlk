import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/constants/colors.dart';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/constants/colors.dart';

class WeatherWidget extends StatefulWidget {
  final String city;

  const WeatherWidget({required this.city, super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String city = 'Loading...';
  String temperature = '--';
  String weatherIcon = '01d';
  String state = '';
  bool isLoading = true;
  bool hasError = false;
  bool isRaining = false;

  @override
  void didUpdateWidget(covariant WeatherWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _fetchWeatherData(); // Re-fetch data when city changes
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeatherData(); // Fetch weather data on init
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final String url =
        'https://api.openweathermap.org/data/2.5/weather?q=${widget.city}&appid=b188ce76a5de0968579278982c1f5b95&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          city = data['name'];
          state = data['sys']['country']; // Get country code or state if available
          temperature = '${data['main']['temp'].round()}°C';
          weatherIcon = data['weather'][0]['icon'];
          isRaining = data['weather'][0]['main'].toLowerCase() == 'rain'; // Check if it is raining
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: TColors.iconGradient.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasError ? 'City not found' : '$city, $state',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Greenhouse Location',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!isLoading && !hasError)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  temperature,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  isRaining ? 'It\'s raining' : 'No rain',
                  style: TextStyle(
                      color: isRaining ? Colors.blueAccent : Colors.greenAccent,
                      fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
