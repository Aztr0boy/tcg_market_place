import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('profiles').select().order('created_at');
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปลี่ยนสิทธิ์เป็น $newRole สำเร็จ'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleBan(String userId, bool isBanned) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('ยืนยันการแบน', style: TextStyle(color: Colors.white)),
        content: const Text('ต้องการเปลี่ยนสถานะแบนของผู้ใช้นี้หรือไม่?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error,
              foregroundColor: isBanned
                ? Theme.of(context).colorScheme.onTertiary
                : Theme.of(context).colorScheme.onError,
            ),
            child: Text(isBanned ? 'ปลดแบน' : 'แบน', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('profiles').update({'is_banned': !isBanned}).eq('id', userId);
      _fetchUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isBanned = user['is_banned'] ?? false;
                final role = user['role'] ?? 'user';

                return Card(
                  color: isBanned
                      ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: role == 'admin'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(isBanned ? Icons.block : Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      user['username'] ?? 'No Name',
                      style: TextStyle(color: isBanned ? Colors.redAccent : Colors.white),
                    ),
                    subtitle: Text('Role: ${role.toUpperCase()}', style: const TextStyle(color: Colors.grey)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      onSelected: (value) {
                        if (value == 'role') _updateRole(user['id'], role);
                        if (value == 'ban') _toggleBan(user['id'], isBanned);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'role', child: Text(role == 'admin' ? 'ปลดเป็น User' : 'ตั้งเป็น Admin', style: const TextStyle(color: Colors.white))),
                        PopupMenuItem(
                          value: 'ban',
                          child: Text(
                            isBanned ? 'ปลดแบน' : 'แบน',
                            style: TextStyle(
                              color: isBanned
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}