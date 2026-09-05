import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_config.dart';
import 'models.dart';

class MatchRepository {
  MatchRepository._();
  static final instance = MatchRepository._();

  final List<MatchModel> _demo = [
    MatchModel(
      id: 'demo-malvin', organizerId: 'demo-user', zone: 'Malvín',
      venue: 'Complejo Malvín', startsAt: DateTime.now().add(const Duration(hours: 3)),
      price: 350, level: 'Intermedio', maxPlayers: 10, playerCount: 9,
    ),
    MatchModel(
      id: 'demo-pocitos', organizerId: 'otro', zone: 'Pocitos',
      venue: 'Cancha Pocitos', startsAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      price: 400, level: 'Recreativo', maxPlayers: 10, playerCount: 7,
    ),
    MatchModel(
      id: 'demo-buceo', organizerId: 'otro2', zone: 'Buceo',
      venue: 'Buceo F5', startsAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
      price: 380, level: 'Intermedio', maxPlayers: 10, playerCount: 8,
    ),
  ];

  SupabaseClient get _db => Supabase.instance.client;
  String get currentUserId => AppConfig.hasSupabase
      ? (_db.auth.currentUser?.id ?? '')
      : 'demo-user';

  Future<List<MatchModel>> upcoming() async {
    if (!AppConfig.hasSupabase) return List.unmodifiable(_demo);

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
      final match = MatchModel(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
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
      _demo.insert(0, match);
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
    });

    return MatchModel.fromMap({...row, 'player_count': 1}, joined: true);
  }

  Future<MatchModel> join(MatchModel match) async {
    if (match.playerCount >= match.totalCapacity) {
      throw Exception('El partido ya tiene titulares y suplente cubiertos.');
    }
    if (!AppConfig.hasSupabase) {
      final updated = match.copyWith(playerCount: match.playerCount + 1, joined: true);
      final index = _demo.indexWhere((m) => m.id == match.id);
      if (index >= 0) _demo[index] = updated;
      return updated;
    }

    await _db.from('match_players').upsert({
      'match_id': match.id,
      'user_id': currentUserId,
      'status': 'confirmed',
    }, onConflict: 'match_id,user_id');

    return match.copyWith(playerCount: match.playerCount + 1, joined: true);
  }

  Future<MatchModel> leave(MatchModel match) async {
    if (!AppConfig.hasSupabase) {
      final updated = match.copyWith(
        playerCount: match.playerCount > 0 ? match.playerCount - 1 : 0,
        joined: false,
      );
      final index = _demo.indexWhere((m) => m.id == match.id);
      if (index >= 0) _demo[index] = updated;
      return updated;
    }

    await _db
        .from('match_players')
        .delete()
        .eq('match_id', match.id)
        .eq('user_id', currentUserId);
    return match.copyWith(playerCount: match.playerCount - 1, joined: false);
  }
}
