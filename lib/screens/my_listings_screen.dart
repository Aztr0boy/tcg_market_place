import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final myId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('รายการสินค้าของฉัน')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔥 1. ดึงข้อมูลของตัวเองมาทั้งหมด (ใช้ eq ได้แค่ 1 อัน เพื่อป้องกัน Error)
        stream: supabase
            .from('marketplace_listings')
            .stream(primaryKey: ['id'])
            .eq('seller_id', myId ?? '')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allMyItems = snapshot.data ?? [];

          // 🔥 2. ใช้ Dart กรองข้อมูลเอาเฉพาะอันที่สถานะยังเป็น 'available'
          final myItems = allMyItems.where((item) => item['status'] == 'available').toList();

          if (myItems.isEmpty) {
            return const Center(
              child: Text('คุณยังไม่มีรายการสินค้าที่กำลังลงขาย', style: TextStyle(fontSize: 16, color: Colors.grey))
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: myItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = myItems[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['image_url'] ?? '', 
                      width: 60, height: 80, fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text('฿${item['price_thb']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  subtitle: Text('สภาพ: ${item['condition']}\nลงเมื่อ: ${DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0]}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, item['id'].toString()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการสินค้า?'),
        content: const Text('รายการสินค้านี้จะถูกซ่อนจากตลาดทันที'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () async {
              try {
                // เปลี่ยนสถานะเป็น deleted แทนการลบข้อมูลทิ้ง
                await Supabase.instance.client
                    .from('marketplace_listings')
                    .update({'status': 'deleted'})
                    .eq('id', id);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}