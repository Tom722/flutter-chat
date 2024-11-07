import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl =
      'https://portal.apps.iytcloud.com/console/api/openapi/chat';

  Stream<String> streamChat(String query) async* {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Authorization': 'Bearer sk-VEug2XmXEmHyFLtSbRBagBgrwMVhCXks',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'app_key': 'app-UtEKZmmxId1HIjQP',
        'query': query,
        'stream': true,
        'conversation_id': 'f2a71524-53cd-4cd8-99be-abb6598b52db',
      }),
    );

    final stream = response.body.split('\n');

    for (var line in stream) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6);
        if (jsonStr.isNotEmpty) {
          try {
            final data = jsonDecode(jsonStr);
            if (data['event'] == 'message' && data['answer'] != null) {
              yield data['answer'];
            }
          } catch (e) {
            print('解析错误: $e');
          }
        }
      }
    }
  }
}
