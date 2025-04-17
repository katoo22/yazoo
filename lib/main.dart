import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_question_page.dart'; // ← هذا مهم

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://awfgtvpbuwrgmrdmomle.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....', // المفاتيح الخاصة بك
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yazoo',
      home: const AddQuestionPage(), // ← هذا هو الموجود لديك فعلاً
    );
  }
}
