import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_room_screen.dart'; 

class CardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const CardDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  bool _isLoadingChat = false;

  Future<void> _startChat() async {
    setState(() => _isLoadingChat = true);
    final supabase = Supabase.instance.client;
    final myId = supabase.auth.currentUser?.id;
    final sellerId = widget.item['seller_id'];
    final listingId = widget.item['id'];

    if (myId == null) return;

    try {
      final existingChat = await supabase
          .from('chats')
          .select('id')
          .eq('buyer_id', myId)
          .eq('seller_id', sellerId)
          .eq('listing_id', listingId)
          .maybeSingle();

      String chatId;

      if (existingChat != null) {
        chatId = existingChat['id'].toString();
      } else {
        final newChat = await supabase.from('chats').insert({
          'buyer_id': myId,
          'seller_id': sellerId,
          'listing_id': listingId,
        }).select('id').single();
        
        chatId = newChat['id'].toString();
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatRoomScreen(chatId: chatId, itemData: widget.item)
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingChat = false);
    }
  }

  Future<void> _deleteListing() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('ยืนยันการลบ', style: TextStyle(color: Colors.white)),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบการ์ดใบนี้ออกจากตลาด?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบการ์ด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('marketplace_listings')
          .delete()
          .eq('id', widget.item['id']);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบการ์ดสำเร็จ'), backgroundColor: Colors.green)
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyItem = myUserId == widget.item['seller_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสินค้า'),
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client.from('profiles').select('role').eq('id', myUserId ?? '').maybeSingle(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data?['role'] == 'admin';
              if (isAdmin || isMyItem) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: _deleteListing,
                );
              }
              return const SizedBox.shrink(); 
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, height: 400, color: Colors.black12,
              child: Image.network(
                widget.item['image_url'] ?? '', fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('฿${widget.item['price_thb']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                      Chip(
                        label: Text(widget.item['condition'] ?? 'ไม่ระบุ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('รายละเอียด / ตำหนิ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(widget.item['description'] ?? '-', style: const TextStyle(fontSize: 16, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: isMyItem || _isLoadingChat ? null : _startChat,
              icon: _isLoadingChat 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(isMyItem ? Icons.inventory : Icons.chat),
              label: Text(
                isMyItem ? 'นี่คือสินค้าของคุณ' : 'แชทกับผู้ขายเพื่อต่อรอง',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMyItem ? Colors.grey[800] : Colors.orange, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}