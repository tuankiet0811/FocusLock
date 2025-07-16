class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isActive;
  final List<String> blockedApps;
  final String? goal;
  final DateTime? pausedTime;
  final int durationSeconds;
  final int? remainingSeconds;

  FocusSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isActive,
    required this.blockedApps,
    this.goal,
    this.pausedTime,
    this.remainingSeconds,
    required this.durationSeconds,
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
      'pausedTime': pausedTime?.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'durationSeconds': durationSeconds,
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
      pausedTime: json['pausedTime'] != null ? DateTime.parse(json['pausedTime']) : null,
      remainingSeconds: json['remainingSeconds'],
      durationSeconds: json['durationSeconds'] ?? (json['durationMinutes'] * 60),
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
    DateTime? pausedTime,
    int? remainingSeconds,
    int? durationSeconds,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      blockedApps: blockedApps ?? this.blockedApps,
      goal: goal ?? this.goal,
      pausedTime: pausedTime ?? this.pausedTime,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
} 