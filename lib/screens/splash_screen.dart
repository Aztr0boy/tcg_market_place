import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // import เพื่อให้เรียกใช้ MainLayout ได้
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) {
      if (session != null) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const MainLayout())
        );
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), //
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.style, size: 100, color: Colors.orange), 
            SizedBox(height: 24),
            Text(
              'TCG MARKET',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.orange), 
          ],
        ),
      ),
    );
  }
}