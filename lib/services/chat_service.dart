import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String baseUrl =
      'https://knowledge-web.apps.iytcloud.com/console/api/openapi/chat';
  final String apiKey = 'sk-OVjS7VE9mT68Uvg7kSFoMnbU6EU836FO';
  final String appKey = 'app-FRP2s2wSx01rsE67';
  String? conversationId;

  Stream<String> chatGPTAPI(String message) async* {
    final client = http.Client();
    var buffer = StringBuffer();

    try {
      final request = http.Request('POST', Uri.parse(baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });

      Map<String, dynamic> requestBody = {
        'app_key': appKey,
        'query': message,
        'stream': true,
      };

      if (conversationId != null) {
        requestBody['conversation_id'] = conversationId as String;
      }

      request.body = jsonEncode(requestBody);

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        DateTime startTime = DateTime.now();

        // 直接处理字节流
        await for (var bytes in streamedResponse.stream) {
          if (DateTime.now().difference(startTime).inMinutes >= 2) {
            throw Exception('请求超时，请稍后重试');
          }

          // 将字节转换为字符串并添加到缓冲区
          String chunk = utf8.decode(bytes);
          buffer.write(chunk);

          // 处理缓冲区中的每一行
          while (buffer.toString().contains('\n')) {
            int newlineIndex = buffer.toString().indexOf('\n');
            String line = buffer.toString().substring(0, newlineIndex).trim();
            buffer =
                StringBuffer(buffer.toString().substring(newlineIndex + 1));

            if (line.startsWith('data: ')) {
              try {
                final jsonStr = line.substring(6);
                final Map<String, dynamic> data = jsonDecode(jsonStr);

                if (data['conversation_id'] != null) {
                  conversationId = data['conversation_id'] as String;
                }

                if (data['event'] == 'message' && data['answer'] != null) {
                  yield data['answer'] as String;
                } else if (data['event'] == 'message_end') {
                  return;
                }
              } catch (e) {
                print('JSON解析错误: $e');
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('请求失败，状态码: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      client.close();
    }
  }

  void clearConversation() {
    conversationId = null;
  }
}
