import 'package:new_idea_works/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';

/// Manages user's sport tab order and visibility.
/// Persists to SharedPreferences.
class SportPrefsProvider extends ChangeNotifier {
  static const _orderKey = 'sport_order';
  static const _hiddenKey = 'sport_hidden';

  /// User-defined order of all sports
  List<SportCategory> _ordered = List.of(SportCategory.values);

  /// Set of hidden sport names
  final Set<String> _hidden = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SportPrefsProvider() {
    _load();
  }

  // ─── Public API ───

  /// All sports in user-defined order (for settings screen)
  List<SportCategory> get allSportsOrdered => List.unmodifiable(_ordered);

  /// Only visible sports in user-defined order (for tab bars)
  List<SportCategory> get visibleSports =>
      _ordered.where((s) => !_hidden.contains(s.name)).toList();

  /// Check if a sport is visible
  bool isVisible(SportCategory sport) => !_hidden.contains(sport.name);

  /// Toggle sport visibility (at least 1 must remain visible)
  void toggleSport(SportCategory sport) {
    if (_hidden.contains(sport.name)) {
      _hidden.remove(sport.name);
    } else {
      // Don't allow hiding the last visible sport
      final visibleCount = _ordered.where((s) => !_hidden.contains(s.name)).length;
      if (visibleCount <= 1) return;
      _hidden.add(sport.name);
    }
    notifyListeners();
    _persist();
  }

  /// Reorder sports (from ReorderableListView callback)
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _ordered.removeAt(oldIndex);
    _ordered.insert(newIndex, item);
    notifyListeners();
    _persist();
  }

  // ─── Persistence ───

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load order
      final orderJson = prefs.getString(_orderKey);
      if (orderJson != null) {
        final orderList = List<String>.from(jsonDecode(orderJson));
        final reordered = <SportCategory>[];
        for (final name in orderList) {
          try {
            reordered.add(SportCategory.values.firstWhere((s) => s.name == name));
          } catch (_) {} // Skip unknown sports
        }
        // Add any new sports that weren't in the saved order
        for (final sport in SportCategory.values) {
          if (!reordered.contains(sport)) {
            reordered.add(sport);
          }
        }
        _ordered = reordered;
      }

      // Load hidden
      final hiddenJson = prefs.getString(_hiddenKey);
      if (hiddenJson != null) {
        _hidden.addAll(List<String>.from(jsonDecode(hiddenJson)));
        // Clean up any stale hidden entries
        _hidden.removeWhere((name) =>
            !SportCategory.values.any((s) => s.name == name));
      }
    } catch (e) {
      appLog('SPORT_PREFS: load error: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _orderKey,
        jsonEncode(_ordered.map((s) => s.name).toList()),
      );
      await prefs.setString(
        _hiddenKey,
        jsonEncode(_hidden.toList()),
      );
    } catch (e) {
      appLog('SPORT_PREFS: persist error: $e');
    }
  }
}
