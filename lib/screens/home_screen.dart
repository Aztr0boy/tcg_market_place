import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              // ปรับส่วน Title ให้แสดง Username แทนชื่อแอปเฉยๆ
              title: FutureBuilder<Map<String, dynamic>?>(
                future: supabase
                    .from('profiles')
                    .select()
                    .eq('id', user?.id ?? '')
                    .maybeSingle(),
                builder: (context, snapshot) {
                  String displayName = "TCG Marketplace";
                  if (snapshot.hasData && snapshot.data != null) {
                    displayName = "สวัสดี, ${snapshot.data!['username']}";
                  }
                  return Text(
                    displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        fontSize: 16),
                  );
                },
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.style,
                    size: 80, color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),

          // ส่วนแสดงสินค้ามาใหม่ล่าสุด
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'สินค้ามาใหม่ล่าสุด',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('marketplace_listings')
                .stream(primaryKey: ['id'])
                .limit(10)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()));
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('ยังไม่มีสินค้าลงขาย')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final bool isSold = item['status'] == 'sold';

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CardDetailScreen(item: item)),
                        ),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      item['image_url'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                    if (isSold)
                                      Container(
                                        color: Colors.black54,
                                        child: const Center(
                                          child: Text('SOLD OUT',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('฿${item['price_thb']}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSold
                                            ? Colors.grey
                                            : Colors.green)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}