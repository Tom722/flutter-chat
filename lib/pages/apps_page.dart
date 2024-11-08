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

  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 4;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newApps = await _appsService.getApps(
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      if (newApps.isEmpty) {
        _hasMoreData = false;
      } else {
        setState(() {
          apps.addAll(newApps);
          _currentPage++;
        });
      }
    } catch (e) {
      // 处理错误，可以显示一个 snackbar 或 toast
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _initializeService() async {
    final User? user = await StorageService.getUser();
    _appsService = AppsService(token: user?.token);
    fetchApps();
  }

  Future<void> fetchApps() async {
    try {
      final appsList = await _appsService.getApps(
        page: 1,
        pageSize: _pageSize,
      );
      setState(() {
        apps = appsList;
        isLoading = false;
        _currentPage = 1;
        _hasMoreData = appsList.length >= _pageSize;
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
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: apps.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == apps.length) {
          return _buildLoadingIndicator();
        }

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

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : _hasMoreData
                ? const SizedBox()
                : const Text('没有更多数据了'),
      ),
    );
  }
}
