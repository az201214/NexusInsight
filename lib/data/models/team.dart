class Team {
  const Team({
    required this.id,
    required this.name,
    required this.createdAt,
    this.themeMode = 'system',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String themeMode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'theme_mode': themeMode,
      };

  factory Team.fromMap(Map<String, dynamic> m) => Team(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        themeMode: m['theme_mode'] as String? ?? 'system',
      );

  Team copyWith({String? name, String? themeMode}) => Team(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        themeMode: themeMode ?? this.themeMode,
      );
}
