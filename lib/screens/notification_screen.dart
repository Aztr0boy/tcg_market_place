import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('การแจ้งเตือน')),
      body: StreamBuilder(
        stream: supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId ?? '').order('created_at', ascending: false),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notifs = snapshot.data!;
          if (notifs.isEmpty) return const Center(child: Text('ไม่มีการแจ้งเตือน'));

          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final notif = notifs[index];
              final isRead = notif['is_read'] ?? false;

              return Container(
                color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.notifications)),
                  title: Text(notif['title'], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(notif['message']),
                  onTap: () async {
                    if (!isRead) await supabase.from('notifications').update({'is_read': true}).eq('id', notif['id']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}