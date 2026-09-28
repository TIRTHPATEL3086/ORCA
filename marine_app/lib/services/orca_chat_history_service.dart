import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/orca_agent_models.dart';

class OrcaChatHistoryService {
  OrcaChatHistoryService._();

  static const _key = 'orca_chat_history_v1';

  static Future<List<OrcaChatMessageData>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(OrcaChatMessageData.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<OrcaChatMessageData> messages) async {
    final prefs = await SharedPreferences.getInstance();

    final trimmed = messages.length > 100
        ? messages.sublist(messages.length - 100)
        : messages;

    await prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
