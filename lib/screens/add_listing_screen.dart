import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({Key? key}) : super(key: key);

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCondition = 'Near Mint'; 
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _conditions = ['Mint', 'Near Mint', 'Excellent', 'Played', 'Poor'];

  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  
  Future<void> _submitListing() async {
    final int? price = int.tryParse(_priceController.text.trim());

    if (_imageFile == null || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรูปภาพและระบุราคาให้ถูกต้อง'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
      final imagePath = 'public/$fileName';

      await supabase.storage.from('card-images').upload(
        imagePath,
        _imageFile!,
      );

      final String imageUrl = supabase.storage.from('card-images').getPublicUrl(imagePath);


      await supabase.from('marketplace_listings').insert({
        'seller_id': userId,
        'price_thb': price,
        'condition': _selectedCondition,
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'status': 'available', 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลงขายการ์ดสำเร็จ!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงขายการ์ด')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('แตะเพื่อเพิ่มรูปการ์ด', style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('ราคาที่ต้องการขาย (บาท)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'เช่น 500',
                    border: OutlineInputBorder(),
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('สภาพการ์ด', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  dropdownColor: const Color(0xFF1E1E1E), 
                  items: _conditions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedCondition = newValue!);
                  },
                ),
                const SizedBox(height: 16),
                const Text('รายละเอียดเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'ระบุตำหนิ หรือข้อมูลเพิ่มเติม...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )
                    ),
                    child: const Text('ลงประกาศขายเลย', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}