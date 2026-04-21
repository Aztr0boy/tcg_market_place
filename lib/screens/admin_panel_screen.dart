import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผงควบคุม Admin'),
        backgroundColor: Colors.redAccent, // ใช้สีแดงให้ดูเป็นแอดมิน
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenu(Icons.add_circle, 'เพิ่มข้อมูลการ์ดใหม่'),
          _buildMenu(Icons.report_problem, 'ตรวจสอบรายการที่ถูกรีพอร์ต'),
          _buildMenu(Icons.campaign, 'ส่งประกาศแจ้งเตือนถึงทุกคน'),
        ],
      ),
    );
  }

  Widget _buildMenu(IconData icon, String title) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title),
        onTap: () { /* ใส่ Logic เปิดหน้าย่อยตรงนี้ */ },
      ),
    );
  }
}