import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'parser.dart';
import 'types.dart';

/// Optional live AI: sends a client message to the Claude Messages API and
/// gets back structured order data. Used only for messages typed by hand
/// in «Своё сообщение» when an API key is set.
class ClaudeException implements Exception {
  ClaudeException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ClaudeClient {
  ClaudeClient({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  static final Uri _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  Future<Map<String, dynamic>> parseOrder(String text) async {
    final http.Response res;
    try {
      res = await http
          .post(
            _endpoint,
            headers: <String, String>{
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
              // Lets the web build call the API straight from the browser.
              'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: jsonEncode(<String, Object>{
              'model': model,
              'max_tokens': 700,
              'messages': <Object>[
                <String, String>{'role': 'user', 'content': claudePrompt(text)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw ClaudeException('Claude не ответил за 45 секунд');
    } catch (e) {
      throw ClaudeException('Нет соединения с Claude: $e');
    }
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw ClaudeException('Claude: HTTP ${res.statusCode} ${_errorMessage(body)}');
    }
    final data = jsonDecode(body);
    final buf = StringBuffer();
    if (data is Map && data['content'] is List) {
      for (final block in data['content'] as List) {
        if (block is Map && block['type'] == 'text') buf.write(block['text']);
      }
    }
    final parsed = extractJson(buf.toString());
    if (parsed is Map<String, dynamic>) return parsed;
    throw ClaudeException('Claude вернул ответ без JSON');
  }

  static String _errorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] is Map) return '${(j['error'] as Map)['message']}';
    } catch (_) {}
    return '';
  }
}

String claudePrompt(String text) {
  final catalog = kCatalog.map((c) => '${c.id} | ${c.ru} | ${c.price}').join('\n');
  return [
    'Ты — ИИ приёма заказов кофейни-пекарни «Дәмді Кофе» в Таразе (Казахстан). Клиент написал в мессенджер на русском или казахском.',
    'Каталог (id | название | цена в тенге):',
    catalog,
    'Сообщение клиента:',
    '"""$text"""',
    'Верни только JSON-объект такого вида, без пояснений:',
    '{"lang":"ru","items":[{"id":"cap","qty":2}],"address_ru":null,"address_kz":null,"far":false,"pickup":false,"phone":null,"time":null,"asks_hours":false,"summary_ru":"","summary_kz":""}',
    'Правила: lang — "ru" или "kz" по языку клиента. items — только id из каталога; у баурсаков qty — число упаковок по 10 штук. '
        'address_ru и address_kz — адрес в Таразе в нормальном виде (например «мкр. Жайлау, 14» и «Жайлау шағын ауданы, 14»), иначе null. '
        'far=true только для мкр. Карасу и мкр. Талас. pickup=true, если клиент заберёт заказ сам. '
        'phone — номер в формате «+7 7XX XXX XX XX» или null. time — желаемое время, если указано, иначе null. '
        'asks_hours=true, если спрашивают часы работы. summary_ru и summary_kz — суть обращения одной короткой фразой на каждом языке.',
  ].join('\n');
}

Object? extractJson(String t) {
  final s = t.trim();
  try {
    return jsonDecode(s);
  } catch (_) {}
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
  if (fence != null) {
    try {
      return jsonDecode(fence[1]!.trim());
    } catch (_) {}
  }
  final a = s.indexOf('{');
  final b = s.lastIndexOf('}');
  if (a >= 0 && b > a) {
    try {
      return jsonDecode(s.substring(a, b + 1));
    } catch (_) {}
  }
  return null;
}

int _clamp99(int v) => v < 1 ? 1 : (v > 99 ? 99 : v);

/// Turns Claude's JSON into an [Analysis], keeping local findings where Claude is silent.
Analysis fromClaude(Map<String, dynamic> r, Analysis local) {
  final qty = <String, int>{};
  final order = <String>[];
  final rawItems = r['items'];
  if (rawItems is List) {
    for (final i in rawItems) {
      if (i is! Map) continue;
      final id = i['id'];
      if (id is! String || !kP.containsKey(id)) continue;
      final int raw = (i['qty'] is num) ? (i['qty'] as num).round() : (int.tryParse('${i['qty']}') ?? 1);
      if (!qty.containsKey(id)) order.add(id);
      qty[id] = _clamp99((qty[id] ?? 0) + _clamp99(raw));
    }
  }
  String? str(Object? v) {
    if (v is! String) return null;
    final x = v.trim();
    if (x.isEmpty) return null;
    return x.length > 140 ? x.substring(0, 140) : x;
  }

  final ar = str(r['address_ru']);
  final ak = str(r['address_kz']);
  final pickup = r['pickup'] == true || local.pickup;
  final a = local.copy()
    ..lang = r['lang'] == 'kz' ? 'kz' : (r['lang'] == 'ru' ? 'ru' : local.lang)
    ..items = <Item>[for (final id in order) Item(id, qty[id]!)]
    ..address = (ar != null || ak != null) ? Bi(ar ?? ak!, ak ?? ar!) : local.address
    ..pickup = pickup
    ..far = pickup ? false : (r['far'] is bool ? r['far'] as bool : local.far)
    ..phone = normPhone(r['phone']) ?? local.phone
    ..time = str(r['time']) != null ? TimeWish(raw: str(r['time'])) : local.time
    ..asksHours = r['asks_hours'] == true || local.asksHours
    ..engine = 'claude';
  final sr = str(r['summary_ru']);
  final sk = str(r['summary_kz']);
  a.summary = (sr != null || sk != null) ? Bi(sr ?? sk!, sk ?? sr!) : null;
  return a;
}
