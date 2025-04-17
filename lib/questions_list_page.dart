import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_screen.dart';
import 'add_question_page.dart';

class QuestionsListPage extends StatefulWidget {
  const QuestionsListPage({super.key});

  @override
  State<QuestionsListPage> createState() => _QuestionsListPageState();
}

class _QuestionsListPageState extends State<QuestionsListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> questions = [];
  String _selectedCategory = 'الكل';
  String _selectedDifficulty = 'الكل';
  bool isGridView = false;

  final List<String> _categories = ['الكل', 'فن عربي', 'فن غربي', 'تاريخ'];
  final List<String> _difficulties = ['الكل', 'سهل', 'متوسط', 'صعب'];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    var query = supabase.from('questions').select();
    if (_selectedCategory != 'الكل') {
      query = query.eq('category', _selectedCategory);
    }
    if (_selectedDifficulty != 'الكل') {
      query = query.eq('difficulty', _selectedDifficulty);
    }
    final response = await query;
    setState(() => questions = List<Map<String, dynamic>>.from(response));
  }

  Widget buildQuestionCard(Map<String, dynamic> q) {
    final fileUrl = q['image_url'];
    final isPdf = fileUrl?.toLowerCase().endsWith('.pdf') ?? false;
    final isVideo = fileUrl?.toLowerCase().endsWith('.mp4') ?? false;
    final isImage = fileUrl != null &&
        (fileUrl.toLowerCase().endsWith('.jpg') ||
            fileUrl.toLowerCase().endsWith('.jpeg') ||
            fileUrl.toLowerCase().endsWith('.png'));
    final fileName =
        fileUrl != null ? Uri.parse(fileUrl).pathSegments.last : '';

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q['question'] ?? '',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('التصنيف: ${q['category'] ?? ''}'),
            Text('الصعوبة: ${q['difficulty'] ?? ''}'),
            const SizedBox(height: 6),
            if (fileUrl != null) ...[
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '$fileUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (isPdf)
                const Icon(Icons.picture_as_pdf, size: 60, color: Colors.red)
              else if (isVideo)
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle),
                  label: const Text("تشغيل الفيديو"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(videoUrl: fileUrl),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 6),
              Text('📎 $fileName', style: const TextStyle(fontSize: 12)),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('تنزيل'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final filePath = Uri.parse(fileUrl).pathSegments.last;
                  await supabase.storage
                      .from('question-images')
                      .remove([filePath]);
                  await supabase
                      .from('questions')
                      .update({'image_url': null}).match({'id': q['id']});
                  _fetchQuestions();
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('حذف المرفق'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddQuestionPage(existingQuestion: q),
                      ),
                    );
                    _fetchQuestions();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await supabase
                        .from('questions')
                        .delete()
                        .match({'id': q['id']});
                    _fetchQuestions();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الأسئلة'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: 'تبديل العرض',
            onPressed: () => setState(() => isGridView = !isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddQuestionPage()),
              );
              _fetchQuestions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val!);
                      _fetchQuestions();
                    },
                    decoration: const InputDecoration(labelText: 'التصنيف'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    items: _difficulties
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedDifficulty = val!);
                      _fetchQuestions();
                    },
                    decoration: const InputDecoration(labelText: 'الصعوبة'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isGridView
                ? GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    children: questions.map(buildQuestionCard).toList(),
                  )
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) =>
                        buildQuestionCard(questions[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
