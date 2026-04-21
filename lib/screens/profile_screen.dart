import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // เพื่อเรียกใช้ themeNotifier
import 'admin_panel_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userEmail = user?.email ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TcgMarketApp()),
                );
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // ส่วนแสดงข้อมูลพื้นฐาน
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(userEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            const Divider(),

            // 🌑 --- ส่วนของ Night Mode Switch ---
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: isDark ? Colors.amber : Colors.blue,
                  ),
                  title: const Text('โหมดกลางคืน (Night Mode)'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (bool value) {
                      // สั่งเปลี่ยนค่าใน main.dart
                      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                );
              },
            ),
            const Divider(),

            // 🛡️ --- ส่วนของ Admin Check ---
            FutureBuilder<Map<String, dynamic>?>(
              future: supabase
                  .from('profiles')
                  .select('role')
                  .eq('id', user?.id ?? '')
                  .maybeSingle(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // ซ่อนไว้ก่อนตอนกำลังโหลด
                }

                if (snapshot.hasData && snapshot.data?['role'] == 'admin') {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      // ปรับสี Card ตาม Theme อัตโนมัติ
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                        title: const Text(
                          'ระบบจัดการ Admin',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('จัดการข่าวสาร การ์ด และรีพอร์ต'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                          );
                        },
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // เมนูอื่นๆ
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('ประวัติการทำรายการ'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('รายการที่ติดตามไว้'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}