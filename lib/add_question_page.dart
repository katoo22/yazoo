import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class AddQuestionPage extends StatefulWidget {
  final Map<String, dynamic>? existingQuestion;

  const AddQuestionPage({super.key, this.existingQuestion});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String _selectedCategory = 'فن عربي';
  String _selectedDifficulty = 'سهل';

  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileUrl;
  String? _existingFilePath;
  bool _isEditing = false;

  final List<String> _categories = ['فن عربي', 'فن غربي', 'تاريخ'];
  final List<String> _difficulties = ['سهل', 'متوسط', 'صعب'];

  @override
  void initState() {
    super.initState();
    if (widget.existingQuestion != null) {
      final q = widget.existingQuestion!;
      _isEditing = true;
      _questionController.text = q['question'] ?? '';
      _answerController.text = q['answer'] ?? '';
      _selectedCategory = q['category'] ?? _selectedCategory;
      _selectedDifficulty = q['difficulty'] ?? _selectedDifficulty;
      _fileUrl = q['image_url'];
      if (_fileUrl != null) {
        _existingFilePath = Uri.parse(_fileUrl!).pathSegments.last;
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
    );

    if (result == null || result.files.single.bytes == null) {
      print('❌ لم يتم اختيار ملف');
      return;
    }

    final Uint8List fileBytes = result.files.single.bytes!;
    final String fileName = result.files.single.name;
    final String sanitizedFileName =
        '${const Uuid().v4()}_${fileName.replaceAll(RegExp(r"[^\w\d._-]"), "_")}';

    final supabase = Supabase.instance.client;

    try {
      if (_existingFilePath != null) {
        await supabase.storage
            .from('question-images')
            .remove([_existingFilePath!]);
      }

      await supabase.storage
          .from('question-images')
          .uploadBinary(sanitizedFileName, fileBytes);

      final publicUrl = supabase.storage
          .from('question-images')
          .getPublicUrl(sanitizedFileName);

      setState(() {
        _fileBytes = fileBytes;
        _fileName = fileName;
        _fileUrl = publicUrl;
        _existingFilePath = sanitizedFileName;
      });

      print('✅ تم رفع المرفق: $publicUrl');
    } catch (e) {
      print('❌ خطأ أثناء رفع المرفق: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في رفع المرفق')),
      );
    }
  }

  void _removeFile() async {
    final supabase = Supabase.instance.client;

    if (_existingFilePath != null) {
      await supabase.storage
          .from('question-images')
          .remove([_existingFilePath!]);
    }

    if (_isEditing && widget.existingQuestion != null) {
      final id = widget.existingQuestion!['id'];
      await supabase
          .from('questions')
          .update({'image_url': null}).match({'id': id});
    }

    setState(() {
      _fileBytes = null;
      _fileName = null;
      _fileUrl = null;
      _existingFilePath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم حذف المرفق')),
    );
  }

  Future<void> _submitQuestion() async {
    final supabase = Supabase.instance.client;
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال السؤال والجواب')),
      );
      return;
    }

    final data = {
      'question': question,
      'answer': answer,
      'category': _selectedCategory,
      'difficulty': _selectedDifficulty,
      'image_url': _fileUrl,
    };

    try {
      if (_isEditing) {
        await supabase
            .from('questions')
            .update(data)
            .match({'id': widget.existingQuestion!['id']});
        print('✏️ تم تعديل السؤال');
      } else {
        await supabase.from('questions').insert(data);
        print('✅ تم إضافة السؤال');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isEditing ? '✅ تم التعديل بنجاح!' : '✅ تم الحفظ بنجاح!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = _fileName?.toLowerCase().endsWith('.pdf') ??
        _fileUrl?.toLowerCase().endsWith('.pdf') == true;
    final isVideo = _fileName?.toLowerCase().endsWith('.mp4') ??
        _fileUrl?.toLowerCase().endsWith('.mp4') == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل سؤال' : 'إضافة سؤال'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'السؤال'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'الجواب'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'التصنيف'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                items: _difficulties
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDifficulty = val!),
                decoration: const InputDecoration(labelText: 'الصعوبة'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text('اختيار مرفق (صورة / PDF / فيديو)'),
                  ),
                  const SizedBox(width: 10),
                  if (_fileUrl != null)
                    TextButton(
                      onPressed: _removeFile,
                      child: const Text('🗑️ حذف المرفق'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_fileBytes != null && isPdf)
                const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red)
              else if (_fileBytes != null && isVideo)
                const Icon(Icons.videocam, size: 80, color: Colors.blue)
              else if (_fileBytes != null)
                Image.memory(_fileBytes!, height: 180)
              else if (_fileUrl != null && isPdf)
                const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red)
              else if (_fileUrl != null && isVideo)
                const Icon(Icons.videocam, size: 80, color: Colors.blue)
              else if (_fileUrl != null)
                Image.network(
                    '$_fileUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                    height: 180),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitQuestion,
                child: Text(_isEditing ? 'تعديل' : 'حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
