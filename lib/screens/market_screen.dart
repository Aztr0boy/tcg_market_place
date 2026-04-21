import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_detail_screen.dart';
import 'add_listing_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('ตลาดซื้อขาย')),
      body: FutureBuilder<List<dynamic>>(
        // สมมติว่าสร้าง View ชื่อ market_feed ไว้แล้ว
        future: supabase.from('marketplace_listings').select('id, price_thb, condition, cards(id, name, image_url), profiles(display_name)').eq('is_deleted', false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('ไม่มีการตั้งขาย'));

          final listings = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final card = listing['cards'];
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: card['id'], cardName: card['name'], imageUrl: card['image_url'] ?? '')));
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Image.network(card['image_url'] ?? 'https://via.placeholder.com/150', fit: BoxFit.cover, width: double.infinity)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                            Text('฿${listing['price_thb']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddListingScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}