import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TCG Market', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // แก้ไข StreamBuilder ให้ระบุ Type เป็น List<Map<String, dynamic>>
          StreamBuilder<List<Map<String, dynamic>>>(
            // ใช้ Stream พื้นฐาน และกรองข้อมูลด้วย .map เพื่อความเสถียร
            stream: supabase
                .from('notifications')
                .stream(primaryKey: ['id'])
                .order('created_at')
                .map((items) => items
                    .where((item) =>
                        item['user_id'] == userId && item['is_read'] == false)
                    .toList()),
            builder: (context, snapshot) {
              // เช็ค Error ป้องกันแอปเด้ง
              if (snapshot.hasError) {
                return const IconButton(
                  icon: Icon(Icons.notifications_off),
                  onPressed: null,
                );
              }

              // ระบุ Type ให้ชัดเจนเพื่อเรียกใช้ .length ได้
              final List<Map<String, dynamic>> unreadNotifications = snapshot.data ?? [];
              final unreadCount = unreadNotifications.length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            },
          )
        ],
      ),
      body: const Center(child: Text('แบนเนอร์ข่าวสาร และ การ์ดมาแรง')),
    );
  }
}