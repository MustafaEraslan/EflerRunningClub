class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.bio,
    required this.avatarPath,
    required this.coachLevel,
    required this.runnerLevel,
  });
  final String id;
  final String fullName;
  final String role;
  final String bio;
  final String? avatarPath;
  final int coachLevel;
  final int runnerLevel;
  bool get canManageRuns => role == 'coach' || role == 'admin';
  bool get canManageCoaches =>
      role == 'admin' || (role == 'coach' && coachLevel == 3);
  String get levelLabel => memberLevelLabel(role, coachLevel, runnerLevel);
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
    bio: json['bio'] as String? ?? '',
    avatarPath: json['avatar_path'] as String?,
    coachLevel: (json['coach_level'] as num?)?.toInt() ?? 0,
    runnerLevel: (json['runner_level'] as num?)?.toInt() ?? 1,
  );
}

class ClubMember {
  const ClubMember({
    required this.id,
    required this.fullName,
    required this.role,
    required this.bio,
    required this.avatarPath,
    required this.coachLevel,
    required this.runnerLevel,
  });
  final String id;
  final String fullName;
  final String role;
  final String bio;
  final String? avatarPath;
  final int coachLevel;
  final int runnerLevel;
  String get levelLabel => memberLevelLabel(role, coachLevel, runnerLevel);
  factory ClubMember.fromJson(Map<String, dynamic> json) => ClubMember(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
    bio: json['bio'] as String? ?? '',
    avatarPath: json['avatar_path'] as String?,
    coachLevel: (json['coach_level'] as num?)?.toInt() ?? 0,
    runnerLevel: (json['runner_level'] as num?)?.toInt() ?? 1,
  );
}

String memberLevelLabel(String role, int coachLevel, int runnerLevel) {
  if (role == 'admin') return 'Yönetici';
  if (role == 'coach') {
    return switch (coachLevel) {
      3 => 'Baş Antrenör',
      2 => 'Kıdemli Antrenör',
      _ => 'Yardımcı Antrenör',
    };
  }
  return switch (runnerLevel) {
    4 => 'Elit',
    3 => 'Tempocu',
    2 => 'Koşucu',
    _ => 'Çaylak',
  };
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
    required this.coachName,
    required this.coachBio,
    required this.coachAvatarPath,
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
  final String coachName;
  final String coachBio;
  final String? coachAvatarPath;
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
    coachName: json['coach_name'] as String? ?? 'Antrenör',
    coachBio: json['coach_bio'] as String? ?? '',
    coachAvatarPath: json['coach_avatar_path'] as String?,
  );
}

class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.stock,
    required this.imagePath,
  });
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final int stock;
  final String? imagePath;
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    pointsCost: json['points_cost'] as int,
    stock: json['stock'] as int,
    imagePath: json['image_url'] as String?,
  );
}
