import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 218,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
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
                    colors: [Color(0xFF071923), Color(0xFF101A2B), Color(0xFF241126)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.style_rounded,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'สินค้ามาใหม่ล่าสุด',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
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
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.tertiary)),
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