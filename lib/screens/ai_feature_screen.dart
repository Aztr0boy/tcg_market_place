import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/ai_assistant_service.dart';
import 'deck_builder_screen.dart';

const _tcgGames = [
  'Pokemon TCG',
  'Yu-Gi-Oh!',
  'Magic: The Gathering',
  'One Piece Card Game',
  'Digimon Card Game',
  'เกมอื่น',
];

class AiFeatureScreen extends StatelessWidget {
  const AiFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI TCG'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.travel_explore), text: 'ค้นคว้าการ์ด'),
              Tab(icon: Icon(Icons.style_outlined), text: 'จัดเด็ค'),
              Tab(icon: Icon(Icons.gavel_outlined), text: 'Ruling'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CardResearchTab(),
            DeckBuilderScreen(embedded: true),
            _RulingTab(),
          ],
        ),
      ),
    );
  }
}

class _CardResearchTab extends StatefulWidget {
  const _CardResearchTab();

  @override
  State<_CardResearchTab> createState() => _CardResearchTabState();
}

class _CardResearchTabState extends State<_CardResearchTab> {
  final _supabase = Supabase.instance.client;
  final _questionController = TextEditingController();
  Timer? _searchTimer;
  List<Map<String, dynamic>> _results = [];
  String _game = _tcgGames.first;
  String? _error;
  String? _answer;
  bool _searching = false;
  bool _asking = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _questionController.dispose();
    super.dispose();
  }

  void _search(String query) {
    _searchTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final cards = await _supabase
            .from('cards')
            .select()
            .ilike('name', '%${query.trim()}%')
            .limit(10);
        if (mounted) {
          setState(() {
            _results = List<Map<String, dynamic>>.from(cards);
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'ค้นหาการ์ดไม่ได้ ตรวจสอบการเชื่อมต่อหรือคลังการ์ด';
            _searching = false;
          });
        }
      }
    });
  }

  Future<void> _askAboutCards() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showMessage('พิมพ์คำถามเกี่ยวกับการ์ดหรือเกมก่อน');
      return;
    }
    setState(() {
      _asking = true;
      _answer = null;
    });
    try {
      final answer = await AiAssistantService.ask(
        mode: 'research',
        game: _game,
        prompt: question,
        cards: _results.take(6).toList(),
      );
      if (mounted) setState(() => _answer = answer);
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCard(Map<String, dynamic> card) async {
    final title = card['name']?.toString() ?? 'รายละเอียดการ์ด';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...card.entries
                  .where((entry) => entry.key != 'id' && entry.key != 'name')
                  .map((entry) {
                final value = entry.value is Map || entry.value is List
                    ? jsonEncode(entry.value)
                    : entry.value?.toString() ?? 'ไม่ระบุ';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: Text(value),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: _search,
          decoration: InputDecoration(
            labelText: 'ค้นหาชื่อการ์ดในคลัง',
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
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_results.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 4),
            child: Text('ผลการค้นหา'),
          ),
          ..._results.map(
            (card) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(card['name']?.toString() ?? 'การ์ด'),
              subtitle: Text(
                card['type']?.toString() ??
                    card['category']?.toString() ??
                    'กดเพื่อดูรายละเอียด',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCard(card),
            ),
          ),
        ],
        const Divider(height: 32),
        Text('ถาม AI เกี่ยวกับเกม', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _game,
          decoration: const InputDecoration(labelText: 'เกมการ์ด'),
          items: _tcgGames
              .map((game) => DropdownMenuItem(value: game, child: Text(game)))
              .toList(),
          onChanged: (game) {
            if (game != null) setState(() => _game = game);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _questionController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'อยากรู้ข้อมูลอะไร',
            hintText: 'ถามเกี่ยวกับความสามารถการ์ด กลยุทธ์ หรือคำศัพท์...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _asking ? null : _askAboutCards,
          icon: _asking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: const Text('ค้นคว้าด้วย AI'),
        ),
        if (_answer != null) _AnswerPanel(answer: _answer!),
      ],
    );
  }
}

class _RulingTab extends StatefulWidget {
  const _RulingTab();

  @override
  State<_RulingTab> createState() => _RulingTabState();
}

class _RulingTabState extends State<_RulingTab> {
  final _questionController = TextEditingController();
  final _contextController = TextEditingController();
  String _game = _tcgGames.first;
  String? _answer;
  bool _asking = false;

  @override
  void dispose() {
    _questionController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _askRuling() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showMessage('อธิบายสถานการณ์หรือพิมพ์คำถามก่อน');
      return;
    }
    setState(() {
      _asking = true;
      _answer = null;
    });
    try {
      final contextText = _contextController.text.trim();
      final answer = await AiAssistantService.ask(
        mode: 'ruling',
        game: _game,
        prompt: [
          if (contextText.isNotEmpty) 'ข้อความการ์ด/สถานการณ์: $contextText',
          'คำถาม: $question',
        ].join('\n'),
      );
      if (mounted) setState(() => _answer = answer);
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('อธิบายสถานการณ์การเล่น', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'AI ช่วยอธิบายกติกาเบื้องต้น แต่ไม่ใช่คำตัดสินจากกรรมการอย่างเป็นทางการ',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _game,
          decoration: const InputDecoration(labelText: 'เกมการ์ด'),
          items: _tcgGames
              .map((game) => DropdownMenuItem(value: game, child: Text(game)))
              .toList(),
          onChanged: (game) {
            if (game != null) setState(() => _game = game);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contextController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'ชื่อการ์ดหรือข้อความสถานการณ์ (ถ้ามี)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _questionController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'คำถาม Ruling',
            hintText: 'เช่น ลำดับการทำงานของเอฟเฟกต์ในสถานการณ์นี้เป็นอย่างไร?',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _asking ? null : _askRuling,
          icon: _asking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.gavel_outlined),
          label: const Text('อธิบาย Ruling'),
        ),
        if (_answer != null) _AnswerPanel(answer: _answer!),
      ],
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(answer),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '');
  if (message.contains('OPENAI_API_KEY') || message.contains('AI is not configured')) {
    return 'AI ยังไม่พร้อมใช้งาน: ตั้งค่า OPENAI_API_KEY และ deploy Supabase Function ก่อน';
  }
  if (message.contains('invalid or expired') || message.contains('Sign in')) {
    return 'เซสชันหมดอายุ กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่';
  }
  return message;
}
