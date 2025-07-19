class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final bool isActive;
  final List<String> blockedApps;
  final String? goal;
  final DateTime? pausedTime;
  final int durationSeconds;
  final int? remainingSeconds;
  final int? actualFocusMinutes; // Thời gian thực tế đã tập trung
  final List<SessionPause> pauseHistory; // Lịch sử pause/resume
  final SessionStatus status; // Trạng thái chi tiết
  final int totalPauseTimeMinutes; // Tổng thời gian pause
  final DateTime? lastActivityTime; // Thời gian hoạt động cuối cùng

  // Computed property to check if session is completed
  bool get isCompleted => status == SessionStatus.completed;
  bool get isPaused => status == SessionStatus.paused;
  bool get isRunning => status == SessionStatus.running;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.isActive,
    required this.blockedApps,
    this.goal,
    this.pausedTime,
    this.remainingSeconds,
    required this.durationSeconds,
    this.actualFocusMinutes,
    this.pauseHistory = const [],
    this.status = SessionStatus.running,
    this.totalPauseTimeMinutes = 0,
    this.lastActivityTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'blockedApps': blockedApps,
      'goal': goal,
      'pausedTime': pausedTime?.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'durationSeconds': durationSeconds,
      'actualFocusMinutes': actualFocusMinutes,
      'pauseHistory': pauseHistory.map((pause) => pause.toJson()).toList(),
      'status': status.name,
      'totalPauseTimeMinutes': totalPauseTimeMinutes,
      'lastActivityTime': lastActivityTime?.toIso8601String(),
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      durationMinutes: json['durationMinutes'],
      isActive: json['isActive'],
      blockedApps: List<String>.from(json['blockedApps']),
      goal: json['goal'],
      pausedTime: json['pausedTime'] != null ? DateTime.parse(json['pausedTime']) : null,
      remainingSeconds: json['remainingSeconds'],
      durationSeconds: json['durationSeconds'] ?? (json['durationMinutes'] * 60),
      actualFocusMinutes: json['actualFocusMinutes'],
      pauseHistory: json['pauseHistory'] != null 
          ? (json['pauseHistory'] as List).map((pause) => SessionPause.fromJson(pause)).toList()
          : [],
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.running,
      ),
      totalPauseTimeMinutes: json['totalPauseTimeMinutes'] ?? 0,
      lastActivityTime: json['lastActivityTime'] != null ? DateTime.parse(json['lastActivityTime']) : null,
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
    int? actualFocusMinutes,
    List<SessionPause>? pauseHistory,
    SessionStatus? status,
    int? totalPauseTimeMinutes,
    DateTime? lastActivityTime,
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
      actualFocusMinutes: actualFocusMinutes ?? this.actualFocusMinutes,
      pauseHistory: pauseHistory ?? this.pauseHistory,
      status: status ?? this.status,
      totalPauseTimeMinutes: totalPauseTimeMinutes ?? this.totalPauseTimeMinutes,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
    );
  }

  // Tính thời gian thực tế đã tập trung
  int calculateActualFocusTime() {
    if (status == SessionStatus.completed) {
      print('FocusSession: Session completed, actualFocusMinutes: ${actualFocusMinutes ?? 0}');
      return actualFocusMinutes ?? 0;
    }
    
    final now = DateTime.now();
    final totalElapsedSeconds = now.difference(startTime).inSeconds;
    final totalElapsedMinutes = (totalElapsedSeconds / 60).floor(); // Làm tròn xuống
    final actualTime = totalElapsedMinutes - totalPauseTimeMinutes;
    
    print('FocusSession: calculateActualFocusTime - startTime: $startTime, now: $now');
    print('FocusSession: totalElapsedSeconds: ${totalElapsedSeconds}s, totalElapsedMinutes: ${totalElapsedMinutes}m');
    print('FocusSession: totalPauseTimeMinutes: $totalPauseTimeMinutes, actualTime: $actualTime');
    
    return actualTime;
  }

  // Tính thời gian còn lại
  int calculateRemainingTime() {
    final actualFocusTime = calculateActualFocusTime();
    return durationMinutes - actualFocusTime;
  }

  // Tính phần trăm hoàn thành
  double calculateCompletionPercentage() {
    final actualFocusTime = calculateActualFocusTime();
    return (actualFocusTime / durationMinutes).clamp(0.0, 1.0);
  }
}

// Enum cho trạng thái session
enum SessionStatus {
  running,
  paused,
  completed,
  cancelled,
}

// Class để track lịch sử pause/resume
class SessionPause {
  final DateTime pauseTime;
  final DateTime? resumeTime;
  final int durationMinutes;

  SessionPause({
    required this.pauseTime,
    this.resumeTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'pauseTime': pauseTime.toIso8601String(),
      'resumeTime': resumeTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory SessionPause.fromJson(Map<String, dynamic> json) {
    return SessionPause(
      pauseTime: DateTime.parse(json['pauseTime']),
      resumeTime: json['resumeTime'] != null ? DateTime.parse(json['resumeTime']) : null,
      durationMinutes: json['durationMinutes'],
    );
  }
} 