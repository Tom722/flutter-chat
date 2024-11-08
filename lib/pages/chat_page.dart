import 'package:flutter/material.dart';

import '../models/app_item.dart';

import '../home_page.dart';

class ChatPage extends StatelessWidget {
  final AppItem app;

  const ChatPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              app.description,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: HomePage(
        customTitle: app.name,
        customDescription: app.description,
        customImageUrl: app.iconUrl,
        hideNavigation: true,
      ),
    );
  }
}
