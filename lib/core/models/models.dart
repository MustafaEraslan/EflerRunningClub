class Profile {
  const Profile({required this.id, required this.fullName, required this.role});
  final String id;
  final String fullName;
  final String role;
  bool get canManageRuns => role == 'coach' || role == 'admin';
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
  );
}

class ClubRun {
  const ClubRun({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.location,
    required this.status,
    required this.points,
    required this.capacity,
    required this.reservedCount,
    required this.isReserved,
  });
  final String id;
  final String title;
  final DateTime startsAt;
  final String location;
  final String status;
  final int points;
  final int capacity;
  final int reservedCount;
  final bool isReserved;
  int get availableSpots => capacity - reservedCount;
  factory ClubRun.fromJson(Map<String, dynamic> json) => ClubRun(
    id: json['id'] as String,
    title: json['title'] as String,
    startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
    location: json['location'] as String,
    status: json['status'] as String,
    points: json['points'] as int,
    capacity: (json['capacity'] as num?)?.toInt() ?? 50,
    reservedCount: (json['reserved_count'] as num?)?.toInt() ?? 0,
    isReserved: json['is_reserved'] as bool? ?? false,
  );
}

class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.stock,
  });
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final int stock;
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    pointsCost: json['points_cost'] as int,
    stock: json['stock'] as int,
  );
}
