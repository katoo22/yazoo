import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://awfgtvpbuwrgmrdmomle.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3Zmd0dnBidXdyZ21yZG1vbWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2NjY3ODMsImV4cCI6MjA2MDI0Mjc4M30.xptPZf7JeNPkxK36M-ajSoeF6ADbtQfSvXftcopAfro',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('اختبار Supabase')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final supabase = Supabase.instance.client;
              try {
                final result = await supabase.from('questions').insert({
                  'question': 'ما عاصمة فرنسا؟',
                  'answer': 'باريس',
                  'category': 'تاريخ',
                });
                print('✅ تم الإدخال: $result');
              } catch (e) {
                print('❌ خطأ في الإدخال: $e');
              }
            },
            child: const Text('أرسل سؤال إلى Supabase'),
          ),
        ),
      ),
    );
  }
}
