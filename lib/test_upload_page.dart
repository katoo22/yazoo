import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'add_question_page.dart'; // لاستدعاء الصفحة الأصلية

class TestUploadPage extends StatefulWidget {
  const TestUploadPage({super.key});

  @override
  State<TestUploadPage> createState() => _TestUploadPageState();
}

class _TestUploadPageState extends State<TestUploadPage> {
  Uint8List? _imageBytes;
  String? _imageUrl;

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final originalName = result.files.single.name;
    final safeName =
        '${const Uuid().v4()}_${originalName.replaceAll(RegExp(r"[^\w\s.-]"), "_")}';

    final supabase = Supabase.instance.client;
    await supabase.storage
        .from('question-images')
        .uploadBinary(safeName, bytes);

    final url = supabase.storage.from('question-images').getPublicUrl(safeName);

    setState(() {
      _imageUrl = url;
    });
  }

  void _goToAddQuestionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddQuestionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار رفع صورة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndUploadImage,
              child: const Text('اختيار ورفع صورة'),
            ),
            const SizedBox(height: 20),
            if (_imageUrl != null)
              Column(
                children: [
                  Text('تم رفع الصورة!'),
                  const SizedBox(height: 10),
                  Image.network(_imageUrl!, height: 200),
                ],
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _goToAddQuestionPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('الذهاب لإضافة سؤال'),
            ),
          ],
        ),
      ),
    );
  }
}
