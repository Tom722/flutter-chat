import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_item.dart';
import '../secrets.dart';

class AppsService {
  final String? token;

  AppsService({this.token});

  Future<List<AppItem>> getApps({int page = 1, int pageSize = 4}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/apps/?page=$page&pageSize=$pageSize'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> appsData = responseData['data'];
      return appsData.map((json) => AppItem.fromJson(json)).toList();
    } else {
      throw Exception('获取应用列表失败: ${response.statusCode}');
    }
  }
}
