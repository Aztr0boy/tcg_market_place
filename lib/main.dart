import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ เพิ่ม Import หน้า Splash Screen เข้ามา
import 'screens/splash_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://mnwtomjiwlslhqfrdvpq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ud3RvbWppd2xzbGhxZnJkdnBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NzA4MjEsImV4cCI6MjA5MjM0NjgyMX0.hrtu48xCfFAXJUDMgCPD4o0JgVxp1cY1N1SHRus1Kqk',
  );

  runApp(const TcgMarketApp());
}

class TcgMarketApp extends StatelessWidget {
  const TcgMarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCG Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, 
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), 
          foregroundColor: Colors.white,
        ),
        cardColor: const Color(0xFF1E1E1E),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.orange, 
          unselectedItemColor: Colors.grey,
        ),
      ),
      // ✅ เปลี่ยนตรงนี้ให้เริ่มที่ SplashScreen เสมอ (แล้วให้ Splash เป็นคนจัดการว่าจะไปหน้าไหนต่อ)
      home: const SplashScreen(),
    );
  }
}

// -------------------------------------------------------------
// ส่วนของ MainLayout (Bottom Navigation Bar) ไม่ต้องแก้ ทำมาดีแล้วครับ!
// -------------------------------------------------------------
class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketScreen(),
    const Center(child: Text('จัดเด็ค (รออัปเดต)')), 
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForNotifications();
    });
  }

  void _listenForNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId).listen((data) {
      if (data.isNotEmpty && mounted) {
        final latestNotif = data.last;
        final createdAt = DateTime.parse(latestNotif['created_at']);
        if (DateTime.now().difference(createdAt).inMinutes < 1 && latestNotif['is_read'] == false) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blueGrey[900],
              content: Text('${latestNotif['title']}\n${latestNotif['message']}'),
              action: SnackBarAction(
                label: 'ดู', 
                textColor: Colors.blueAccent,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'ตลาด'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'จัดเด็ค'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}