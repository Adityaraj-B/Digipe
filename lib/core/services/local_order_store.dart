import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the web app's `deletedIds` localStorage pattern —
/// customer "delete" is a local-only hide, since there is no
/// customer-facing DELETE /api/orders/:id endpoint (only admin has one).
class LocalOrderStore {
  static const _key = 'digipe_hidden_order_ids';

  static Future<Set<String>> getHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> hideOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet();
    ids.add(orderId);
    await prefs.setStringList(_key, ids.toList());
  }
}