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

  // ฟังก์ชันเลือกรูปจากแกลเลอรี
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // ฟังก์ชันอัปโหลดรูปและบันทึกข้อมูลลง Database
  Future<void> _submitListing() async {
    // แปลงข้อความราคาเป็นตัวเลข (ป้องกันแอปเด้งถ้าพิมพ์ตัวอักษร)
    final int? price = int.tryParse(_priceController.text.trim());

    // ตรวจสอบความครบถ้วนของข้อมูล
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
      // 1. อัปโหลดรูปไปที่ Bucket 'card-images'
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
      final imagePath = 'public/$fileName';

      await supabase.storage.from('card-images').upload(
        imagePath,
        _imageFile!,
      );

      // 2. ดึง Public URL ของรูปออกมา
      final String imageUrl = supabase.storage.from('card-images').getPublicUrl(imagePath);

      // 3. บันทึกข้อมูลทั้งหมดลงในตาราง marketplace_listings
      await supabase.from('marketplace_listings').insert({
        'seller_id': userId,
        'price_thb': price,
        'condition': _selectedCondition,
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'status': 'available', // ✅ แก้ให้ตรงกับ Constraint ในฐานข้อมูล
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลงขายการ์ดสำเร็จ!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // ปิดหน้านี้เมื่อลงขายเสร็จ
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
                // ส่วนแสดงและเลือกรูป
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E), // ✅ เปลี่ยนสีกล่องให้เข้ากับ Dark Mode
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
                
                // กรอกราคา
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

                // เลือกสภาพการ์ด
                const Text('สภาพการ์ด', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  dropdownColor: const Color(0xFF1E1E1E), // ✅ ให้เมนู Dropdown สีเข้ากับ Dark Mode
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

                // รายละเอียด
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

                // ปุ่มยืนยัน
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, // ✅ ใช้สีส้มเพื่อให้เด่นใน Dark Mode
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