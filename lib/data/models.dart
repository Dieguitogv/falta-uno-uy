class MatchModel {
  final String id;
  final String organizerId;
  final String zone;
  final String venue;
  final DateTime startsAt;
  final int price;
  final String level;
  final int maxPlayers;
  final int playerCount;
  final bool joined;

  int get totalCapacity => maxPlayers + 1; // titulares + 1 suplente de seguridad
  bool get startersFull => playerCount >= maxPlayers;
  bool get reserveFull => playerCount >= totalCapacity;
  bool get currentUserIsReserve => joined && playerCount > maxPlayers;

  const MatchModel({
    required this.id,
    required this.organizerId,
    required this.zone,
    required this.venue,
    required this.startsAt,
    required this.price,
    required this.level,
    required this.maxPlayers,
    required this.playerCount,
    this.joined = false,
  });


  Map<String, dynamic> toMap() => {
        'id': id,
        'organizer_id': organizerId,
        'zone': zone,
        'venue': venue,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'price_per_player': price,
        'level': level,
        'max_players': maxPlayers,
        'player_count': playerCount,
        'joined': joined,
      };

  MatchModel copyWith({int? playerCount, bool? joined}) => MatchModel(
        id: id,
        organizerId: organizerId,
        zone: zone,
        venue: venue,
        startsAt: startsAt,
        price: price,
        level: level,
        maxPlayers: maxPlayers,
        playerCount: playerCount ?? this.playerCount,
        joined: joined ?? this.joined,
      );

  factory MatchModel.fromMap(Map<String, dynamic> map, {bool? joined}) {
    return MatchModel(
      id: map['id'].toString(),
      organizerId: map['organizer_id'].toString(),
      zone: (map['zone'] ?? '').toString(),
      venue: (map['venue'] ?? '').toString(),
      startsAt: DateTime.parse(map['starts_at'].toString()).toLocal(),
      price: (map['price_per_player'] as num?)?.toInt() ?? 0,
      level: (map['level'] ?? 'Cualquiera').toString(),
      maxPlayers: (map['max_players'] as num?)?.toInt() ?? 10,
      playerCount: (map['player_count'] as num?)?.toInt() ?? 1,
      joined: joined ?? (map['joined'] == true),
    );
  }
}

class PlayerProfile {
  final String id;
  final String name;
  final String position;
  final String zone;
  final double rating;
  final int matches;
  final int attendance;

  const PlayerProfile({
    required this.id,
    required this.name,
    required this.position,
    required this.zone,
    required this.rating,
    required this.matches,
    required this.attendance,
  });
}
