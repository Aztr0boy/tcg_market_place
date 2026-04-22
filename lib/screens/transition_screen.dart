import 'package:flutter/material.dart';
import '../main.dart'; // ✅ 1. ต้อง import ไฟล์ main.dart เข้ามาเพื่อเรียกใช้ MainLayout

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({Key? key}) : super(key: key);

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
    // โชว์หน้าโหลดนี้ค้างไว้ 1.5 วินาที
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        // ✅ 2. เปลี่ยนตรงนี้จาก HomeScreen() เป็น MainLayout()
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // เปลี่ยนเป็นสีดำตามธีม
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.style, size: 100, color: Colors.orange),
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
            CircularProgressIndicator(color: Colors.orange),
          ],
        ),
      ),
    );
  }
}