import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  Map<String, int> _stats = {'users': 0, 'available': 0, 'sold': 0};
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      final usersRes = await supabase.from('profiles').select('id');
      final availableRes = await supabase.from('marketplace_listings').select('id').eq('status', 'available');
      final soldRes = await supabase.from('marketplace_listings').select('id').eq('status', 'sold');
      final usersList = await supabase.from('profiles').select().order('created_at', ascending: false);

      setState(() {
        _stats = {
          'users': usersRes.length,
          'available': availableRes.length,
          'sold': soldRes.length,
        };
        _users = List<Map<String, dynamic>>.from(usersList);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _updateRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      _fetchAdminData(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปลี่ยนสิทธิ์เป็น $newRole สำเร็จ'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
  Future<void> _toggleBan(String userId, bool isBanned) async {
    final actionName = isBanned ? 'ปลดแบน' : 'แบน';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('ยืนยันการ$actionName', style: const TextStyle(color: Colors.white)),
        content: Text('แน่ใจหรือไม่ว่าต้องการ $actionName ผู้ใช้นี้?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green : Colors.redAccent),
            child: Text(actionName, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('profiles').update({'is_banned': !isBanned}).eq('id', userId);
      _fetchAdminData(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        title: const Text('ศูนย์ควบคุม Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAdminData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _fetchAdminData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ภาพรวมตลาด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard('ผู้ใช้ทั้งหมด', _stats['users'] ?? 0, Icons.people, Colors.blue),
                        const SizedBox(width: 12),
                        _buildStatCard('การ์ดที่ลงขาย', _stats['available'] ?? 0, Icons.storefront, Colors.orange),
                        const SizedBox(width: 12),
                        _buildStatCard('ขายออกแล้ว', _stats['sold'] ?? 0, Icons.check_circle, Colors.green),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text('รายชื่อผู้ใช้งานระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    
                    ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isBanned = user['is_banned'] ?? false;
                        final role = user['role'] ?? 'user';
                        final isMe = user['id'] == supabase.auth.currentUser?.id;

                        return Card(
                          color: isBanned ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isBanned ? Colors.redAccent : Colors.transparent),
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: role == 'admin' ? Colors.orange : Colors.blueGrey,
                              child: Icon(isBanned ? Icons.block : (role == 'admin' ? Icons.admin_panel_settings : Icons.person), color: Colors.white),
                            ),
                            title: Text(
                              user['username'] ?? 'No Name',
                              style: TextStyle(
                                color: isBanned ? Colors.redAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: isBanned ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text('Role: ${role.toUpperCase()}', style: TextStyle(color: role == 'admin' ? Colors.orangeAccent : Colors.white54, fontSize: 12)),
                            trailing: isMe 
                              ? const Chip(label: Text('คุณ', style: TextStyle(fontSize: 10)), backgroundColor: Colors.white12) 
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  color: const Color(0xFF334155),
                                  onSelected: (value) {
                                    if (value == 'role') _updateRole(user['id'], role);
                                    if (value == 'ban') _toggleBan(user['id'], isBanned);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'role', 
                                      child: Text(role == 'admin' ? 'ปลดแอดมิน' : 'ตั้งเป็นแอดมิน', style: const TextStyle(color: Colors.white))
                                    ),
                                    PopupMenuItem(
                                      value: 'ban', 
                                      child: Text(isBanned ? 'ปลดแบน' : 'แบนผู้ใช้', style: TextStyle(color: isBanned ? Colors.green : Colors.redAccent))
                                    ),
                                  ],
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}