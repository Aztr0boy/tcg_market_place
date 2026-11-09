import 'package:flutter/material.dart';
import '../main.dart'; 

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({super.key});

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndMoveToHome();
  }

  Future<void> _loadDataAndMoveToHome() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.style_rounded, size: 100, color: Color(0xFF32F5FF)),
            SizedBox(height: 24),
            Text(
              'กำลังเตรียมข้อมูล...', 
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF32F5FF)),
          ],
        ),
      ),
    );
  }
}