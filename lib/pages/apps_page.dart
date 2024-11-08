import 'package:flutter/material.dart';
import '../models/app_item.dart';
import '../pallete.dart';

class AppsPage extends StatelessWidget {
  AppsPage({super.key});

  final List<AppItem> apps = [
    AppItem(
      id: '1',
      name: '文章助手',
      description: '帮助您撰写高质量的文章，提供创意和灵感',
      imageUrl: 'assets/images/article.png',
    ),
    AppItem(
      id: '2',
      name: '代码专家',
      description: '解答编程问题，优化代码结构，提供最佳实践',
      imageUrl: 'assets/images/code.png',
    ),
    AppItem(
      id: '3',
      name: '翻译助手',
      description: '精准翻译多国语言，支持专业术语翻译',
      imageUrl: 'assets/images/translate.png',
    ),
    AppItem(
      id: '4',
      name: '数学导师',
      description: '解决数学问题，讲解数学概念和公式',
      imageUrl: 'assets/images/math.png',
    ),
    AppItem(
      id: '5',
      name: '生活顾问',
      description: '提供日常生活建议，解答各类生活问题',
      imageUrl: 'assets/images/life.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Pallete.firstSuggestionBoxColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps,
                size: 30,
                color: Pallete.firstSuggestionBoxColor,
              ),
            ),
            title: Text(
              app.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                app.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: app,
              );
            },
          ),
        );
      },
    );
  }
}
