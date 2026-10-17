import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diskusifihk/screens/login_screen.dart';
import 'package:diskusifihk/screens/home_screen.dart';

void main() {
  runApp(const DiskusifihkApp());
}

class DiskusifihkApp extends StatefulWidget {
  const DiskusifihkApp({super.key});

  @override
  State<DiskusifihkApp> createState() => _DiskusifihkAppState();
}

class _DiskusifihkAppState extends State<DiskusifihkApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    if (mounted) {
      setState(() {
        _isLoggedIn = userId != null && userId.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      title: 'Diskusi Fiqih Kontemporer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}