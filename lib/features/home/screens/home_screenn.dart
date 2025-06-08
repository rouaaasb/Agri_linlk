import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Don't forget this
import '../../../utils/helpers/weather_service.dart';
import '../../controlroom/screens/controlroom_two.dart';
import 'settings_screen.dart';
import '../../../utils/constants/colors.dart';
import '../../sensors/screens/inside_humidity_screen.dart';
import '../../sensors/screens/inside_temp_screen.dart';
import '../../sensors/screens/soil_humidity_screen.dart';
import '../../sensors/screens/soil_temp_screen.dart';
import '../../sensors/screens/air_quality_screen.dart';
import '../../sensors/screens/brightness_screen.dart';
import '../../sensors/screens/water_level_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentCity = 'Tunis'; // Default city for Tunisia

  @override
  void initState() {
    super.initState();
    _loadCity(); // Load saved city on app start
  }

  void _updateCity(String newCity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', newCity);
    setState(() {
      _currentCity = newCity;
    });
  }

  void _loadCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCity = prefs.getString('selectedCity');
    if (savedCity != null) {
      setState(() {
        _currentCity = savedCity;
      });
    }
  }

  void _changeCityDialog(BuildContext context) {
    String cityName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change City"),
        content: TextField(
          decoration: const InputDecoration(hintText: "Enter city name"),
          onChanged: (value) {
            cityName = value;
          },
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              if (cityName.isNotEmpty) {
                _updateCity(cityName);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city, color: Colors.black),
            onPressed: () => _changeCityDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeatherWidget(city: _currentCity),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1,
                children: [
                  _SensorButton(label: 'Inside Humidity', icon: Icons.water_drop, page: const InsideHumidityScreen()),
                  _SensorButton(label: 'Inside Temp', icon: Icons.thermostat, page: const InsideTemperatureScreen()),
                  _SensorButton(label: 'Soil Humidity', icon: Icons.grass, page: const SoilHumidityScreen()),
                  _SensorButton(label: 'Soil Temp', icon: Icons.thermostat_auto, page: const SoilTempScreen()),
                  _SensorButton(label: 'Air Quality', icon: Icons.air, page: const AirQualityScreen()),
                  _SensorButton(label: 'Brightness', icon: Icons.wb_sunny, page: const BrightnessScreen()),
                  _SensorButton(label: 'Water Level', icon: Icons.waves, page: const WaterLevelScreen()), // Added Water Level Sensor
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainNavBar(currentIndex: 0),
    );
  }
}

class _SensorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget page;

  const _SensorButton({
    required this.label,
    required this.icon,
    required this.page,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) => TColors.iconGradient.createShader(bounds),
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
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
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
            break;
          case 1:
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ControlRoomTwo()));
            break;
          case 2:
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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