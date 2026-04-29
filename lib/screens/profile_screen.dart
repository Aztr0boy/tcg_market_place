import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; 
import 'admin_panel_screen.dart';
import 'add_listing_screen.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false, // false คือล้าง stack เก่าทิ้ง
                );
              }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: supabase.from('profiles').select('username, role').eq('id', user?.id ?? '').maybeSingle(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          final data = snapshot.data;
          final fallbackName = user?.email?.split('@')[0] ?? 'Unknown';
          final String username = data?['username'] ?? fallbackName;
          final String role = data?['role'] ?? 'user';
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 16),
                Text(
                  username, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                Text(
                  user?.email ?? '', 
                  style: const TextStyle(fontSize: 14, color: Colors.grey)
                ),
                const SizedBox(height: 32),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_photo_alternate_outlined, color: Colors.blueAccent),
                  title: const Text('ลงประกาศขายการ์ด'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt_rounded, color: Colors.greenAccent),
                  title: const Text('รายการสินค้าของฉัน'),
                  subtitle: const Text('จัดการสินค้าและลบรายการ', style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen())),
                ),
                const Divider(),
                if (role == 'admin')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: Colors.red.withValues(alpha: 0.15), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                        title: const Text('ระบบจัดการ Admin', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        subtitle: const Text('จัดการข่าวสารและรีพอร์ต', style: TextStyle(color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}