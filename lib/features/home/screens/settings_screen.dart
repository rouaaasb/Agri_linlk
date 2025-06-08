import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import '../../../utils/constants/colors.dart';
import '../../authentication/screens/login/login.dart';
import '../../controlroom/screens/controlroom_two.dart';
import 'home_screenn.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Firebase Realtime Database reference for system status
  final DatabaseReference _systemStatusRef = FirebaseDatabase.instance.ref('system');

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  Future<void> _removeAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.delete();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          _showReauthenticateDialog(context, () async {
            await _removeAccount(context);
          });
        } else {
          print('Error deleting account: ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: ${e.message}')),
          );
        }
      } catch (e) {
        print('Unexpected error deleting account: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    }
  }

  void _showReauthenticateDialog(BuildContext context, VoidCallback onReauthenticate) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter your password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final credential = EmailAuthProvider.credential(
                      email: user.email!, password: passwordController.text.trim());
                  await user.reauthenticateWithCredential(credential);
                  Navigator.of(context).pop();
                  onReauthenticate();
                }
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Re-authentication failed: ${e.message}')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you really want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showRemoveAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: const Text('Are you sure you want to permanently remove your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _removeAccount(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
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
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.black),
            title: const Text('Notifications', style: TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.chevron_right, color: Colors.black38),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black),
            title: const Text('About Us', style: TextStyle(fontSize: 18)),
          ),
          const Divider(indent: 16, endIndent: 16),
          StreamBuilder<DatabaseEvent>(
            stream: _systemStatusRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                final isConnected = snapshot.data!.snapshot.value as bool? ?? false;

                return ListTile(
                  leading: Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  title: const Text('ESP32 Connection', style: TextStyle(fontSize: 18)),
                  trailing: Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return const ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.orange),
                  title: Text('SYSTEM Connection', style: TextStyle(fontSize: 18)),
                  trailing: Text('Error', style: TextStyle(color: Colors.orange)),
                );
              } else {
                return const ListTile(
                  leading: Icon(Icons.wifi_tethering, color: Colors.grey),
                  title: Text('SYSTEM Connection', style: TextStyle(fontSize: 18)),
                  trailing: Text('Checking...', style: TextStyle(color: Colors.grey)),
                );
              }
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.redAccent)),
            onTap: () => _showLogoutDialog(context),
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Remove Account', style: TextStyle(fontSize: 18, color: Colors.red)),
            onTap: () => _showRemoveAccountDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: const MainNavBar(currentIndex: 2),
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