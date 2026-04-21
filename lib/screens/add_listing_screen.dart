import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({Key? key}) : super(key: key);

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _priceController = TextEditingController();
  final _supabase = Supabase.instance.client;

  Future<void> _submitListing() async {
    // ต้องมี card_id จริงๆ ในระบบก่อนลงขาย (อันนี้ใส่ Hardcode จำลอง)
    final mockCardId = 'YOUR_CARD_UUID_HERE'; 
    await _supabase.from('marketplace_listings').insert({
      'seller_id': _supabase.auth.currentUser!.id,
      'card_id': mockCardId,
      'price_thb': int.parse(_priceController.text),
      'condition': 'Mint',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงขายการ์ด')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ราคา (บาท)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitListing, child: const Text('ลงขาย'))
          ],
        ),
      ),
    );
  }
}