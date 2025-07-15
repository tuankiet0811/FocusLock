class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isActive;
  final List<String> blockedApps;
  final String? goal;

  FocusSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isActive,
    required this.blockedApps,
    this.goal,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'blockedApps': blockedApps,
      'goal': goal,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      durationMinutes: json['durationMinutes'],
      isActive: json['isActive'],
      blockedApps: List<String>.from(json['blockedApps']),
      goal: json['goal'],
    );
  }

  FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? isActive,
    List<String>? blockedApps,
    String? goal,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      blockedApps: blockedApps ?? this.blockedApps,
      goal: goal ?? this.goal,
    );
  }
} 