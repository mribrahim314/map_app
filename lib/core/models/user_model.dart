import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class AppUser extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String role;

  @HiveField(2)
  final bool requestSent;

  @HiveField(3)
  final int contributionCount;

  AppUser({
    required this.name,
    required this.role,
    required this.requestSent,
    required this.contributionCount,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      requestSent: map['requestSent'] ?? false,
      contributionCount: map['contributionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'requestSent': requestSent,
      'contributionCount': contributionCount,
    };
  }
  AppUser copyWith({
  String? name,
  String? role,
  bool? requestSent,
  int? contributionCount,
}) {
  return AppUser(
    name: name ?? this.name,
    role: role ?? this.role,
    requestSent: requestSent ?? this.requestSent,
    contributionCount: contributionCount ?? this.contributionCount,
  );
}
}

