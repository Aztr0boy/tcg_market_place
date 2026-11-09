import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_assistant_service.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final List<Map<String, dynamic>> _deck = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _scanMatches = [];
  Timer? _searchTimer;
  String _recognizedText = '';
  String? _searchError;
  bool _searching = false;
  bool _scanning = false;
  bool _loadingDeck = true;
  bool _saving = false;
  bool _analyzingDeck = false;
  String _selectedGame = 'Pokemon TCG';

  int get _deckSize => _deck.fold<int>(
        0,
        (total, card) => total + (card['quantity'] as int? ?? 1),
      );

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _recognizer.close();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString('saved_tcg_deck');
      if (encoded != null) {
        final cards = jsonDecode(encoded) as List<dynamic>;
        _deck.addAll(cards.map((card) => Map<String, dynamic>.from(card as Map)));
      }
    } catch (_) {
      if (mounted) _showMessage('โหลดเด็คที่บันทึกไว้ไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _loadingDeck = false);
    }
  }

  void _searchCards(String query) {
    _searchTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final cards = await _supabase
            .from('cards')
            .select()
            .ilike('name', '%${query.trim()}%')
            .limit(8);
        if (mounted) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(cards);
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _searchError = 'ค้นหาการ์ดไม่สำเร็จ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';
            _searching = false;
          });
        }
      }
    });
  }

  String _cardType(Map<String, dynamic> card, {String text = ''}) {
    for (final key in ['type', 'card_type', 'category', 'supertype', 'subtype']) {
      final value = card[key]?.toString() ?? '';
      if (value.trim().isNotEmpty) return _translateType(value);
    }
    return _translateType(text);
  }

  String _translateType(String value) {
    final type = value.toLowerCase();
    if (type.contains('pokemon') || type.contains('โปเกมอน')) return 'โปเกมอน';
    if (type.contains('trainer') || type.contains('supporter')) return 'เทรนเนอร์';
    if (type.contains('energy')) return 'พลังงาน';
    if (type.contains('creature') || type.contains('monster')) return 'มอนสเตอร์';
    if (type.contains('spell') || type.contains('sorcery')) return 'เวทมนตร์';
    if (type.contains('trap')) return 'กับดัก';
    if (type.contains('item')) return 'ไอเทม';
    if (type.contains('stadium')) return 'สนาม';
    return value.trim().isEmpty ? 'ไม่ระบุประเภท' : value;
  }

  Future<void> _scanCard() async {
    final supported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supported) {
      _showMessage('การสแกนด้วย AI รองรับบนแอป Android และ iOS');
      return;
    }
    setState(() => _scanning = true);
    try {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      if (!mounted) return;
      setState(() {
        _recognizedText = recognized.text;
        _scanMatches = [];
      });
      await _findScannedCards(recognized.text);
    } catch (_) {
      if (mounted) _showMessage('สแกนไม่สำเร็จ ลองถ่ายภาพให้ชัดขึ้น');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _findScannedCards(String text) async {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= 3 && line.length <= 45)
        .take(6);
    final matches = <String, Map<String, dynamic>>{};
    for (final line in lines) {
      final cards = await _supabase
          .from('cards')
          .select()
          .ilike('name', '%$line%')
          .limit(5);
      for (final card in cards) {
        final item = Map<String, dynamic>.from(card);
        final id = item['id']?.toString() ?? item['name']?.toString();
        if (id != null) matches[id] = item;
      }
      if (matches.length >= 5) break;
    }
    if (mounted) setState(() => _scanMatches = matches.values.take(5).toList());
  }

  void _addCard(Map<String, dynamic> card) {
    final name = card['name']?.toString() ?? 'การ์ดไม่ระบุชื่อ';
    final id = card['id']?.toString() ?? name.toLowerCase();
    final index = _deck.indexWhere((item) => item['id'] == id);
    setState(() {
      if (index < 0) {
        _deck.add({'id': id, 'name': name, 'type': _cardType(card), 'quantity': 1});
      } else {
        _deck[index]['quantity'] = (_deck[index]['quantity'] as int) + 1;
      }
      _searchResults = [];
      _scanMatches = [];
    });
    _persistDeck();
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      final quantity = (_deck[index]['quantity'] as int) + delta;
      if (quantity == 0) {
        _deck.removeAt(index);
      } else {
        _deck[index]['quantity'] = quantity;
      }
    });
    _persistDeck();
  }

  Future<bool> _persistDeck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_tcg_deck', jsonEncode(_deck));
      return true;
    } catch (_) {
      if (mounted) _showMessage('บันทึกเด็คในเครื่องไม่สำเร็จ');
      return false;
    }
  }

  Future<void> _saveDeck() async {
    setState(() => _saving = true);
    final saved = await _persistDeck();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) _showMessage('บันทึกเด็คไว้ในอุปกรณ์แล้ว');
  }

  Future<void> _analyzeDeck() async {
    if (_deck.isEmpty || _analyzingDeck) return;
    setState(() => _analyzingDeck = true);
    try {
      final answer = await AiAssistantService.ask(
        mode: 'deck',
        game: _selectedGame,
        prompt: 'วิเคราะห์แผนการเล่น จุดแข็ง จุดอ่อน และเสนอแนวทางปรับเด็ค โดยระบุข้อสมมติเรื่องรูปแบบการเล่น',
        cards: _deck,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI วิเคราะห์เด็ค'),
          content: SingleChildScrollView(child: Text(answer)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _analyzingDeck = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _cardTile(Map<String, dynamic> card, {String text = ''}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(card['name']?.toString() ?? 'การ์ด'),
      subtitle: Text(_cardType(card, text: text)),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: () => _addCard(card),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('จัดเด็ค')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _searchCards,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาการ์ดเพื่อเพิ่มเข้าเด็ค...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'สแกนการ์ดด้วยกล้อง',
                  onPressed: _scanning ? null : _scanCard,
                  icon: _scanning
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGame,
              decoration: const InputDecoration(
                labelText: 'เกมการ์ด',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                'Pokemon TCG',
                'Yu-Gi-Oh!',
                'Magic: The Gathering',
                'One Piece Card Game',
                'Digimon Card Game',
                'เกมอื่น',
              ].map((game) => DropdownMenuItem(value: game, child: Text(game))).toList(),
              onChanged: (game) {
                if (game != null) setState(() => _selectedGame = game);
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (_recognizedText.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ผลสแกนและประเภทการ์ด',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _recognizedText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_scanMatches.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('ยังจับคู่ชื่อการ์ดในฐานข้อมูลไม่ได้'),
                            )
                          else ...[
                            const Divider(),
                            ..._scanMatches.map(
                              (card) => _cardTile(card, text: _recognizedText),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _searchError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (_searchResults.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 4),
                    child: Text('ผลการค้นหา'),
                  ),
                  ..._searchResults.map(_cardTile),
                  const Divider(),
                ],
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'รายการการ์ดในเด็ค',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Text('$_deckSize ใบ'),
                  ],
                ),
                if (_deck.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _analyzingDeck ? null : _analyzeDeck,
                      icon: _analyzingDeck
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_outlined),
                      label: const Text('วิเคราะห์และแนะนำเด็คด้วย AI'),
                    ),
                  ),
                if (_loadingDeck)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_deck.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: Text('เด็คว่างเปล่า เริ่มเพิ่มการ์ดกันเลย')),
                  )
                else
                  ..._deck.asMap().entries.map((entry) {
                    final index = entry.key;
                    final card = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.style_outlined),
                      title: Text(card['name']?.toString() ?? 'การ์ด'),
                      subtitle: Text(card['type']?.toString() ?? 'ไม่ระบุประเภท'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'ลดจำนวน',
                            onPressed: () => _changeQuantity(index, -1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${card['quantity'] ?? 1}'),
                          IconButton(
                            tooltip: 'เพิ่มจำนวน',
                            onPressed: () => _changeQuantity(index, 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveDeck,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text('บันทึกเด็ค ($_deckSize ใบ)'),
              ),
            ),
    );
  }
}