import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import 'models.dart';

class MatchRepository {
  MatchRepository._();
  static final instance = MatchRepository._();

  static const _localKey = 'falta_uno_uy_matches_v5';
  List<MatchModel>? _localCache;

  SupabaseClient get _db => Supabase.instance.client;
  String get currentUserId => AppConfig.hasSupabase
      ? (_db.auth.currentUser?.id ?? '')
      : 'local-user';

  List<MatchModel> _seedMatches() => [
        MatchModel(
          id: 'demo-malvin',
          organizerId: currentUserId,
          zone: 'Malvín',
          venue: 'Complejo Malvín',
          startsAt: DateTime.now().add(const Duration(hours: 3)),
          price: 350,
          level: 'Intermedio',
          maxPlayers: 10,
          playerCount: 9,
          joined: true,
        ),
        MatchModel(
          id: 'demo-pocitos',
          organizerId: 'otro',
          zone: 'Pocitos',
          venue: 'Cancha Pocitos',
          startsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
          price: 400,
          level: 'Recreativo',
          maxPlayers: 10,
          playerCount: 7,
        ),
      ];

  Future<List<MatchModel>> _localMatches() async {
    if (_localCache != null) return _localCache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) {
      _localCache = _seedMatches();
      await _saveLocal();
      return _localCache!;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _localCache = decoded
          .map((e) => MatchModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _localCache = _seedMatches();
      await _saveLocal();
    }
    return _localCache!;
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final matches = _localCache ?? <MatchModel>[];
    await prefs.setString(_localKey, jsonEncode(matches.map((m) => m.toMap()).toList()));
  }

  Future<List<MatchModel>> upcoming() async {
    if (!AppConfig.hasSupabase) {
      final local = await _localMatches();
      local.removeWhere((m) => m.startsAt.isBefore(DateTime.now().subtract(const Duration(hours: 3))));
      local.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      await _saveLocal();
      return List.unmodifiable(local);
    }

    final rows = await _db
        .from('matches_with_counts')
        .select()
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .eq('status', 'open')
        .order('starts_at');

    final joinedRows = await _db
        .from('match_players')
        .select('match_id')
        .eq('user_id', currentUserId)
        .eq('status', 'confirmed');
    final joinedIds = joinedRows.map((e) => e['match_id'].toString()).toSet();

    return rows
        .map<MatchModel>((row) => MatchModel.fromMap(
              Map<String, dynamic>.from(row),
              joined: joinedIds.contains(row['id'].toString()),
            ))
        .toList();
  }

  Future<MatchModel> create({
    required String zone,
    required String venue,
    required DateTime startsAt,
    required int price,
    required String level,
    required int maxPlayers,
  }) async {
    if (!AppConfig.hasSupabase) {
      final local = await _localMatches();
      final match = MatchModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        organizerId: currentUserId,
        zone: zone,
        venue: venue,
        startsAt: startsAt,
        price: price,
        level: level,
        maxPlayers: maxPlayers,
        playerCount: 1,
        joined: true,
      );
      local.insert(0, match);
      await _saveLocal();
      return match;
    }

    final row = await _db.from('matches').insert({
      'organizer_id': currentUserId,
      'zone': zone,
      'venue': venue,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'price_per_player': price,
      'level': level,
      'max_players': maxPlayers,
    }).select().single();

    await _db.from('match_players').insert({
      'match_id': row['id'],
      'user_id': currentUserId,
      'status': 'confirmed',
      'role': 'starter',
    });

    return MatchModel.fromMap({...row, 'player_count': 1}, joined: true);
  }

  Future<MatchModel> join(MatchModel match) async {
    if (match.playerCount >= match.totalCapacity) {
      throw Exception('El partido ya tiene 10 titulares y 1 suplente cubiertos.');
    }
    if (!AppConfig.hasSupabase) {
      final local = await _localMatches();
      final updated = match.copyWith(playerCount: match.playerCount + 1, joined: true);
      final index = local.indexWhere((m) => m.id == match.id);
      if (index >= 0) local[index] = updated;
      await _saveLocal();
      return updated;
    }

    final role = match.playerCount >= match.maxPlayers ? 'reserve' : 'starter';
    await _db.from('match_players').upsert({
      'match_id': match.id,
      'user_id': currentUserId,
      'status': 'confirmed',
      'role': role,
    }, onConflict: 'match_id,user_id');

    return match.copyWith(playerCount: match.playerCount + 1, joined: true);
  }

  Future<MatchModel> leave(MatchModel match) async {
    if (!AppConfig.hasSupabase) {
      final local = await _localMatches();
      final updated = match.copyWith(
        playerCount: match.playerCount > 0 ? match.playerCount - 1 : 0,
        joined: false,
      );
      final index = local.indexWhere((m) => m.id == match.id);
      if (index >= 0) local[index] = updated;
      await _saveLocal();
      return updated;
    }

    await _db.rpc('leave_match_and_promote_reserve', params: {'p_match_id': match.id});
    return match.copyWith(playerCount: match.playerCount - 1, joined: false);
  }
}
