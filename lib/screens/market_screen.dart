import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_detail_screen.dart';
import 'add_listing_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตลาดการ์ด')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาการ์ด...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('marketplace_listings')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('โหลดตลาดไม่สำเร็จ ลองอีกครั้ง'));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // กรองข้อมูลตามคำค้นหา
                final items = snapshot.data!.where((i) => 
                  '${i['description'] ?? ''} ${i['name'] ?? ''}'
                      .toLowerCase()
                      .contains(_searchQuery.trim().toLowerCase())
                ).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(_searchQuery.isEmpty ? 'ยังไม่มีรายการในตลาด' : 'ไม่พบการ์ดที่ค้นหา'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bool isSold = item['status'] == 'sold';

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => CardDetailScreen(item: item))
                        ),
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
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Center(child: Icon(Icons.style_outlined, size: 36)),
                                    ),
                                  ),
                                  if (isSold)
                                    Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: Text('ขายแล้ว', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['description']?.toString().trim().isNotEmpty == true
                                        ? item['description'].toString()
                                        : 'การ์ดสะสม',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '฿${item['price_thb']}',
                                    style: TextStyle(
                                      color: isSold
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => const AddListingScreen())
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}