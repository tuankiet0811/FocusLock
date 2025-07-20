import 'session_status.dart';

class SessionHistory {
  final String id;
  final String sessionId;
  final DateTime timestamp;
  final SessionAction action;
  final Map<String, dynamic> data;
  final String? note;

  SessionHistory({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.action,
    this.data = const {},
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'action': action.name,
      'data': data,
      'note': note,
    };
  }

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'],
      sessionId: json['sessionId'],
      timestamp: DateTime.parse(json['timestamp']),
      action: SessionAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => SessionAction.unknown,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      note: json['note'],
    );
  }
}

enum SessionAction {
  started,
  paused,
  resumed,
  completed,
  cancelled,
  appBlocked,
  appUnblocked,
  goalSet,
  goalAchieved,
  unknown,
}

class SessionStatistics {
  final String sessionId;
  final int totalFocusMinutes;
  final int totalPauseMinutes;
  final int totalSessions;
  final int completedSessions;
  final int cancelledSessions;
  final double averageSessionLength;
  final double completionRate;
  final List<String> mostBlockedApps;
  final Map<String, int> appBlockCounts;
  final DateTime? lastSessionDate;
  final int currentStreak;
  final int longestStreak;

  SessionStatistics({
    required this.sessionId,
    required this.totalFocusMinutes,
    required this.totalPauseMinutes,
    required this.totalSessions,
    required this.completedSessions,
    required this.cancelledSessions,
    required this.averageSessionLength,
    required this.completionRate,
    required this.mostBlockedApps,
    required this.appBlockCounts,
    this.lastSessionDate,
    required this.currentStreak,
    required this.longestStreak,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'totalFocusMinutes': totalFocusMinutes,
      'totalPauseMinutes': totalPauseMinutes,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'cancelledSessions': cancelledSessions,
      'averageSessionLength': averageSessionLength,
      'completionRate': completionRate,
      'mostBlockedApps': mostBlockedApps,
      'appBlockCounts': appBlockCounts,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  factory SessionStatistics.fromJson(Map<String, dynamic> json) {
    return SessionStatistics(
      sessionId: json['sessionId'],
      totalFocusMinutes: json['totalFocusMinutes'],
      totalPauseMinutes: json['totalPauseMinutes'],
      totalSessions: json['totalSessions'],
      completedSessions: json['completedSessions'],
      cancelledSessions: json['cancelledSessions'],
      averageSessionLength: json['averageSessionLength'].toDouble(),
      completionRate: json['completionRate'].toDouble(),
      mostBlockedApps: List<String>.from(json['mostBlockedApps']),
      appBlockCounts: Map<String, int>.from(json['appBlockCounts']),
      lastSessionDate: json['lastSessionDate'] != null ? DateTime.parse(json['lastSessionDate']) : null,
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
    );
  }

  SessionStatistics copyWith({
    String? sessionId,
    int? totalFocusMinutes,
    int? totalPauseMinutes,
    int? totalSessions,
    int? completedSessions,
    int? cancelledSessions,
    double? averageSessionLength,
    double? completionRate,
    List<String>? mostBlockedApps,
    Map<String, int>? appBlockCounts,
    DateTime? lastSessionDate,
    int? currentStreak,
    int? longestStreak,
  }) {
    return SessionStatistics(
      sessionId: sessionId ?? this.sessionId,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalPauseMinutes: totalPauseMinutes ?? this.totalPauseMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      cancelledSessions: cancelledSessions ?? this.cancelledSessions,
      averageSessionLength: averageSessionLength ?? this.averageSessionLength,
      completionRate: completionRate ?? this.completionRate,
      mostBlockedApps: mostBlockedApps ?? this.mostBlockedApps,
      appBlockCounts: appBlockCounts ?? this.appBlockCounts,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
} 