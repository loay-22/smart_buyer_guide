import 'dart:convert';

import 'package:hive/hive.dart';

import '../../data/models/search_history_entry.dart';

class HistoryRepository {
  static const _boxName = 'history';

  Future<List<SearchHistoryEntry>> loadHistory() async {
    final box = await _historyBox();
    return box.values
        .map((value) => SearchHistoryEntry.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            ))
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveHistory(List<SearchHistoryEntry> entries) async {
    final box = await _historyBox();
    await box.clear();
    for (final entry in entries) {
      await box.add(jsonEncode(entry.toJson()));
    }
  }

  Future<void> addEntry(SearchHistoryEntry entry) async {
    final entries = await loadHistory();
    entries.insert(0, entry);
    await saveHistory(entries);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await loadHistory();
    entries.removeWhere((entry) => entry.id == id);
    await saveHistory(entries);
  }

  Future<void> clearAll() async {
    final box = await _historyBox();
    await box.clear();
  }

  Future<Box<String>> _historyBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }
}
