import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_data.dart';

/// Stockage local de la carte du consultant.
class ProfileStore {
  static const _key = 'acg-carte-v1';

  static Future<CardData?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      return CardData.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  static Future<void> save(CardData card) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(card.toJson()),
    );
  }
}
