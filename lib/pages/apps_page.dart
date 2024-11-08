import 'package:flutter/material.dart';
import '../services/apps_service.dart';
import '../models/app_item.dart';
import '../pallete.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  late final AppsService _appsService;
  List<AppItem> apps = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final User? user = await StorageService.getUser();
    _appsService = AppsService(token: user?.token);
    fetchApps();
  }

  Future<void> fetchApps() async {
    try {
      final appsList = await _appsService.getApps();
      setState(() {
        apps = appsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  app.iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.apps,
                      size: 30,
                      color: Pallete.firstSuggestionBoxColor,
                    );
                  },
                ),
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
