import 'session_status.dart';

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
    
    // Nếu session đang pause, tính đến thời điểm pause
    final endTime = this.endTime ?? (status == SessionStatus.paused ? pausedTime : now);
    
    if (endTime == null) {
      print('FocusSession: Không thể tính thời gian thực tế - endTime và pausedTime đều null');
      return 0;
    }
    
    // Tính tổng thời gian đã trôi qua (tính bằng giây)
    final totalElapsedSeconds = endTime.difference(startTime).inSeconds;
    
    // Tính tổng thời gian pause (tính bằng giây)
    int totalPauseSeconds = 0;
    for (final pause in pauseHistory) {
      if (pause.resumeTime != null) {
        // Nếu có resumeTime, tính thời gian pause chính xác
        totalPauseSeconds += pause.resumeTime!.difference(pause.pauseTime).inSeconds;
      } else if (status == SessionStatus.paused && pause.pauseTime == pausedTime) {
        // Nếu đang pause và đây là pause cuối cùng, tính đến thời điểm hiện tại
        totalPauseSeconds += now.difference(pause.pauseTime).inSeconds;
      }
    }
    
    // Tính thời gian thực tế = tổng thời gian - tổng thời gian pause
    final actualFocusSeconds = totalElapsedSeconds - totalPauseSeconds;
    final calculatedActualFocusMinutes = (actualFocusSeconds / 60).floor(); // Làm tròn xuống
    
    print('FocusSession: calculateActualFocusTime - startTime: $startTime, endTime: $endTime');
    print('FocusSession: totalElapsedSeconds: ${totalElapsedSeconds}s');
    print('FocusSession: totalPauseSeconds: ${totalPauseSeconds}s');
    print('FocusSession: actualFocusSeconds: ${actualFocusSeconds}s, calculatedActualFocusMinutes: ${calculatedActualFocusMinutes}m');
    
    return calculatedActualFocusMinutes.clamp(0, durationMinutes); // Đảm bảo không âm và không vượt quá duration
  }

  // Tính thời gian còn lại
  int calculateRemainingTime() {
    final actualFocusTime = calculateActualFocusTime();
    return durationMinutes - actualFocusTime;
  }

  // Tính phần trăm hoàn thành dựa trên thời gian đã trôi qua
  double calculateCompletionPercentage() {
    final now = DateTime.now();
    
    // Nếu session đã hoàn thành
    if (status == SessionStatus.completed) {
      return 1.0; // 100% hoàn thành
    }
    
    // Nếu session đang pause, tính đến thời điểm pause
    final currentTime = status == SessionStatus.paused ? pausedTime : now;
    
    if (currentTime == null) {
      return 0.0;
    }
    
    // Tính thời gian đã trôi qua (tính bằng giây)
    final elapsedSeconds = currentTime.difference(startTime).inSeconds;
    
    // Tính tổng thời gian pause (tính bằng giây)
    int totalPauseSeconds = 0;
    for (final pause in pauseHistory) {
      if (pause.resumeTime != null) {
        // Nếu có resumeTime, tính thời gian pause chính xác
        totalPauseSeconds += pause.resumeTime!.difference(pause.pauseTime).inSeconds;
      } else if (status == SessionStatus.paused && pause.pauseTime == pausedTime) {
        // Nếu đang pause và đây là pause cuối cùng, tính đến thời điểm hiện tại
        totalPauseSeconds += now.difference(pause.pauseTime).inSeconds;
      }
    }
    
    // Tính thời gian thực tế đã trôi qua (không tính thời gian pause)
    final actualElapsedSeconds = elapsedSeconds - totalPauseSeconds;
    
    // Tính phần trăm hoàn thành
    final percentage = (actualElapsedSeconds / durationSeconds).clamp(0.0, 1.0);
    
    print('FocusSession: calculateCompletionPercentage - elapsedSeconds: ${elapsedSeconds}s, totalPauseSeconds: ${totalPauseSeconds}s');
    print('FocusSession: actualElapsedSeconds: ${actualElapsedSeconds}s, durationSeconds: ${durationSeconds}s, percentage: ${percentage * 100}%');
    
    return percentage;
  }
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