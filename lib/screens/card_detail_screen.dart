import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardDetailScreen extends StatefulWidget {
  final String cardId;
  final String cardName;
  final String imageUrl;

  const CardDetailScreen({Key? key, required this.cardId, required this.cardName, required this.imageUrl}) : super(key: key);

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final supabase = Supabase.instance.client;
  bool isWatching = false;

  @override
  void initState() {
    super.initState();
    _checkWatchStatus();
  }

  Future<void> _checkWatchStatus() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase.from('watchlists').select().eq('user_id', userId!).eq('card_id', widget.cardId).maybeSingle();
    if (mounted) setState(() => isWatching = response != null);
  }

  Future<void> _toggleWatchlist() async {
    final userId = supabase.auth.currentUser?.id;
    if (isWatching) {
      await supabase.from('watchlists').delete().eq('user_id', userId!).eq('card_id', widget.cardId);
    } else {
      await supabase.from('watchlists').insert({'user_id': userId, 'card_id': widget.cardId});
    }
    setState(() => isWatching = !isWatching);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isWatching ? 'เปิดแจ้งเตือนแล้ว' : 'ยกเลิกการแจ้งเตือน')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardName),
        actions: [
          IconButton(
            icon: Icon(isWatching ? Icons.notifications_active : Icons.notifications_none, color: isWatching ? Colors.amber : Colors.grey),
            onPressed: _toggleWatchlist,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(widget.imageUrl, height: 300),
            const SizedBox(height: 16),
            Text(widget.cardName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('ปุ่มยื่นข้อเสนอ หรือแชทกับผู้ขาย จะอยู่ตรงนี้'),
            )
          ],
        ),
      ),
    );
  }
}