import 'package:flutter/material.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คอลเลกชันของฉัน')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text('มูลค่าตลาดปัจจุบัน (พอร์ตของคุณ)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 8),
                Text('฿15,400.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 4),
                    Text('+฿450 (3.2%)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                )
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('คุณยังไม่ได้เพิ่มการ์ดลงในคอลเลกชัน', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}