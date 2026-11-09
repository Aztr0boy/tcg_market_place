import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart'; 
import 'screens/home_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/ai_feature_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://mnwtomjiwlslhqfrdvpq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ud3RvbWppd2xzbGhxZnJkdnBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NzA4MjEsImV4cCI6MjA5MjM0NjgyMX0.hrtu48xCfFAXJUDMgCPD4o0JgVxp1cY1N1SHRus1Kqk',
  );

  runApp(const TcgMarketApp());
}

class TcgMarketApp extends StatelessWidget {
  const TcgMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF32F5FF),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF32F5FF),
      onPrimary: const Color(0xFF041316),
      secondary: const Color(0xFFFF4FD8),
      onSecondary: const Color(0xFF26051F),
      tertiary: const Color(0xFFC8FF4D),
      onTertiary: const Color(0xFF172000),
      surface: const Color(0xFF0F1721),
      surfaceContainerHighest: const Color(0xFF182431),
      outlineVariant: const Color(0xFF29404C),
    );

    return MaterialApp(
      title: 'TCG Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF080D14),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF080D14),
          foregroundColor: colorScheme.onSurface,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 3,
          shadowColor: colorScheme.primary.withValues(alpha: 0.12),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.7),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: colorScheme.primary,
          linearTrackColor: colorScheme.primary.withValues(alpha: 0.18),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: const Color(0xFF0B121B),
          indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.surfaceContainerHighest,
          contentTextStyle: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;
  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketScreen(),
    const AiFeatureScreen(),
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
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI TCG'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}