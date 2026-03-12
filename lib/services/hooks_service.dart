import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hook.dart';

class HooksService {
  final SupabaseClient _client;

  HooksService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches hooks, optionally filtered by category.
  Future<List<Hook>> getHooks({String? category}) async {
    var query = _client.from('hooks').select();
    if (category != null) {
      query = query.eq('category', category);
    }
    final data = await query;
    return data.map((json) => Hook.fromJson(json)).toList();
  }

  /// Fetches distinct categories for a dropdown/picker.
  Future<List<String>> getCategories() async {
    final data = await _client.from('hooks').select('category');
    return data.map((row) => row['category'] as String).toSet().toList();
  }
}
