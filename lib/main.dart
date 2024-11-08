import 'package:allen/home_page.dart';
import 'package:allen/pallete.dart';
import 'package:flutter/material.dart';
import 'package:allen/pages/login_page.dart';
import 'package:allen/services/storage_service.dart';
import 'package:allen/models/user.dart';
import 'package:allen/models/app_item.dart';
import 'package:allen/pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Assistent',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.whiteColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Pallete.whiteColor,
        ),
      ),
      home: FutureBuilder<User?>(
        future: StorageService.getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return snapshot.hasData ? const HomePage() : const LoginPage();
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (context) => const HomePage());
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (context) => const LoginPage());
        }
        if (settings.name == '/chat') {
          final args = settings.arguments;
          if (args is AppItem) {
            return MaterialPageRoute(
              builder: (context) => ChatPage(app: args),
            );
          }
          return MaterialPageRoute(builder: (context) => const HomePage());
        }
        return MaterialPageRoute(builder: (context) => const HomePage());
      },
    );
  }
}
