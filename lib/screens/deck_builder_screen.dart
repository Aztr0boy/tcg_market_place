import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({Key? key}) : super(key: key);

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myDeck = [];
  List<dynamic> _searchResults = [];

  void _searchCards(String query) async {
    if (query.isEmpty) return;
    final results = await _supabase
        .from('cards')
        .select()
        .ilike('name', '%$query%')
        .limit(5);
    setState(() => _searchResults = results);
  }

  void _addToDeck(dynamic card) {
    setState(() {
      _myDeck.add(card);
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดเด็ค (Deck Builder)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _searchCards,
              decoration: InputDecoration(
                hintText: 'ค้นหาการ์ดเพื่อเพิ่มเข้าเด็ค...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final card = _searchResults[index];
                  return ListTile(
                    title: Text(card['name']),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addToDeck(card),
                  );
                },
              ),
            ),
          const Divider(),
          const Text('รายการการ์ดในเด็ค', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(
            child: _myDeck.isEmpty
                ? const Center(child: Text('เด็คว่างเปล่า เริ่มเพิ่มการ์ดกันเลย!'))
                : ListView.builder(
                    itemCount: _myDeck.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.style),
                        title: Text(_myDeck[index]['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => setState(() => _myDeck.removeAt(index)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.blueGrey[50],
            child: ElevatedButton(
              onPressed: () { /* บันทึกเด็คลงตาราง user_decks */ },
              child: Text('บันทึกเด็ค (${_myDeck.length} ใบ)'),
            ),
          )
        ],
      ),
    );
  }
}