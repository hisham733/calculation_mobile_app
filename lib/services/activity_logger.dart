import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log.dart';

class ActivityLogger {
  static const String _key = 'activity_logs';
  static const int _maxEntries = 200;

  static Future<List<ActivityLog>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    final list = (jsonDecode(s) as List).cast<Map<String, dynamic>>();
    return list.map((e) => ActivityLog.fromMap(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> log({
    required String action,
    required String description,
    String? details,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    final list = s != null ? (jsonDecode(s) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    list.add(ActivityLog(
      timestamp: DateTime.now(),
      action: action,
      description: description,
      details: details,
    ).toMap());

    if (list.length > _maxEntries) {
      list.removeRange(0, list.length - _maxEntries);
    }

    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
