import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:kakejiku_app/barrel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/story/story.json');
  final story = Story.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  runApp(Kakejiku(story: story));
}

class Kakejiku extends StatelessWidget {
  const Kakejiku({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: story.meta.title,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: StoryView(story: story),
      ),
    );
  }
}
