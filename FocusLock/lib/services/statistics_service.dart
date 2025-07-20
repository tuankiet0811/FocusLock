import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';
import '../models/session_history.dart';
import '../models/session_status.dart';
import 'storage_service.dart';
import '../utils/helpers.dart';

class StatisticsService extends ChangeNotifier {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final StorageService _storageService = StorageService();
  
  List<FocusSession> _sessions = [];
  List<SessionHistory> _history = [];
  SessionStatistics? _currentStatistics;
  
  // Getters
  List<FocusSession> get sessions => _sessions;
  List<SessionHistory> get history => _history;
  SessionStatistics? get currentStatistics => _currentStatistics;

  // Initialize service
  Future<void> init() async {
    await _storageService.init();
    await _loadData();
    await _calculateStatistics();
    notifyListeners();
  }

  // Load data from storage
  Future<void> _loadData() async {
    _sessions = await _storageService.getFocusSessions();
    _history = await _storageService.getSessionHistory();
  }

  // Debug method để kiểm tra statistics
  void debugStatistics() {
    print('=== DEBUG STATISTICS ===');
    print('Total Sessions: ${_sessions.length}');
    print('Total History Entries: ${_history.length}');
    
    if (_currentStatistics != null) {
      print('Current Statistics:');
      print('  Total Focus Minutes: ${_currentStatistics!.totalFocusMinutes}');
      print('  Total Sessions: ${_currentStatistics!.totalSessions}');
      print('  Completed Sessions: ${_currentStatistics!.completedSessions}');
      print('  Cancelled Sessions: ${_currentStatistics!.cancelledSessions}');
      print('  Completion Rate: ${_currentStatistics!.completionRate}');
      print('  Average Session Length: ${_currentStatistics!.averageSessionLength}');
    }
    
    // Debug sessions
    for (int i = 0; i < _sessions.length; i++) {
      final session = _sessions[i];
      print('Session $i:');
      print('  ID: ${session.id}');
      print('  Status: ${session.status}');
      print('  Duration: ${session.durationMinutes}');
      print('  Actual Focus: ${session.actualFocusMinutes}');
      print('  Calculated Actual: ${session.calculateActualFocusTime()}');
      print('  Pause History: ${session.pauseHistory.length} entries');
    }
    
    print('========================');
  }

  // Fix sessions và recalculate statistics
  Future<void> fixSessionsAndRecalculate() async {
    print('StatisticsService: Bắt đầu fix sessions và recalculate statistics');
    
    // Recalculate actualFocusMinutes cho tất cả sessions
    for (int i = 0; i < _sessions.length; i++) {
      final session = _sessions[i];
      final calculatedActualTime = session.calculateActualFocusTime();
      
      if (session.actualFocusMinutes != calculatedActualTime) {
        print('StatisticsService: Fix session ${session.id} - old: ${session.actualFocusMinutes}, new: $calculatedActualTime');
        
        final fixedSession = session.copyWith(
          actualFocusMinutes: calculatedActualTime,
        );
        
        _sessions[i] = fixedSession;
        await _storageService.updateFocusSession(fixedSession);
      }
    }
    
    // Recalculate statistics
    await _calculateStatistics();
    notifyListeners();
    
    print('StatisticsService: Đã fix và recalculate statistics');
  }

  // Add session history entry
  Future<void> addHistoryEntry({
    required String sessionId,
    required SessionAction action,
    Map<String, dynamic> data = const {},
    String? note,
  }) async {
    print('StatisticsService: Thêm history entry - Action: ${action.name}, SessionId: $sessionId, Note: $note');
    
    // Kiểm tra xem có entry trùng lặp gần đây không (trong vòng 5 giây)
    final now = DateTime.now();
    final recentEntries = _history.where((entry) => 
      entry.sessionId == sessionId && 
      entry.action == action &&
      now.difference(entry.timestamp).inSeconds < 5
    ).toList();
    
    if (recentEntries.isNotEmpty) {
      print('StatisticsService: Phát hiện entry trùng lặp, bỏ qua');
      return;
    }
    
    final entry = SessionHistory(
      id: Helpers.generateId(),
      sessionId: sessionId,
      timestamp: now,
      action: action,
      data: data,
      note: note,
    );

    _history.add(entry);
    await _storageService.addSessionHistory(entry);
    await _calculateStatistics();
    notifyListeners();
  }

  // Calculate comprehensive statistics
  Future<void> _calculateStatistics() async {
    if (_sessions.isEmpty) {
      _currentStatistics = SessionStatistics(
        sessionId: '',
        totalFocusMinutes: 0,
        totalPauseMinutes: 0,
        totalSessions: 0,
        completedSessions: 0,
        cancelledSessions: 0,
        averageSessionLength: 0.0,
        completionRate: 0.0,
        mostBlockedApps: [],
        appBlockCounts: {},
        currentStreak: 0,
        longestStreak: 0,
      );
      return;
    }

    // Calculate basic statistics
    final completedSessions = _sessions.where((s) => s.status == SessionStatus.completed).toList();
    final cancelledSessions = _sessions.where((s) => s.status == SessionStatus.cancelled).toList();
    
    int totalFocusMinutes = 0;
    int totalPauseMinutes = 0;
    final appBlockCounts = <String, int>{};
    final blockedAppsList = <String>[];

    for (final session in _sessions) {
      // Calculate actual focus time
      int actualFocusTime = 0; // Khởi tạo mặc định
      if (session.status == SessionStatus.completed || session.status == SessionStatus.cancelled) {
        // Sử dụng actualFocusMinutes đã lưu cho các session đã kết thúc
        actualFocusTime = session.actualFocusMinutes ?? session.calculateActualFocusTime();
      } else {
        // Tính toán real-time cho session đang chạy
        actualFocusTime = session.calculateActualFocusTime();
      }
      
      totalFocusMinutes += actualFocusTime;
      totalPauseMinutes += session.totalPauseTimeMinutes;

      // Track blocked apps
      for (final app in session.blockedApps) {
        appBlockCounts[app] = (appBlockCounts[app] ?? 0) + 1;
        if (!blockedAppsList.contains(app)) {
          blockedAppsList.add(app);
        }
      }
    }

    // Calculate averages and rates
    final averageSessionLength = _sessions.isNotEmpty 
        ? _sessions.map((s) => s.durationMinutes).reduce((a, b) => a + b) / _sessions.length
        : 0.0;
    
    final completionRate = _sessions.isNotEmpty 
        ? completedSessions.length / _sessions.length
        : 0.0;

    // Calculate streaks
    final streakData = _calculateStreaks();

    // Get most blocked apps
    final sortedApps = appBlockCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostBlockedApps = sortedApps.take(5).map((e) => e.key).toList();

    _currentStatistics = SessionStatistics(
      sessionId: _sessions.isNotEmpty ? _sessions.last.id : '',
      totalFocusMinutes: totalFocusMinutes,
      totalPauseMinutes: totalPauseMinutes,
      totalSessions: _sessions.length,
      completedSessions: completedSessions.length,
      cancelledSessions: cancelledSessions.length,
      averageSessionLength: averageSessionLength,
      completionRate: completionRate,
      mostBlockedApps: mostBlockedApps,
      appBlockCounts: appBlockCounts,
      lastSessionDate: _sessions.isNotEmpty ? _sessions.last.startTime : null,
      currentStreak: streakData['currentStreak'] ?? 0,
      longestStreak: streakData['longestStreak'] ?? 0,
    );

    await _storageService.saveStatistics(_currentStatistics!);
  }

  // Calculate streaks
  Map<String, int> _calculateStreaks() {
    if (_sessions.isEmpty) return {'currentStreak': 0, 'longestStreak': 0};

    final completedSessions = _sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (completedSessions.isEmpty) return {'currentStreak': 0, 'longestStreak': 0};

    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastSessionDate;

    for (final session in completedSessions) {
      final sessionDate = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      
      if (lastSessionDate == null) {
        currentStreak = 1;
        longestStreak = 1;
        lastSessionDate = sessionDate;
      } else {
        final daysDifference = lastSessionDate.difference(sessionDate).inDays;
        
        if (daysDifference == 1) {
          currentStreak++;
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
        } else if (daysDifference > 1) {
          break; // Streak broken
        }
        // If daysDifference == 0, it's the same day, continue
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // Get statistics for specific period
  SessionStatistics getStatisticsForPeriod(DateTime start, DateTime end) {
    final periodSessions = _sessions.where((session) {
      return session.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
             session.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    if (periodSessions.isEmpty) {
      return SessionStatistics(
        sessionId: '',
        totalFocusMinutes: 0,
        totalPauseMinutes: 0,
        totalSessions: 0,
        completedSessions: 0,
        cancelledSessions: 0,
        averageSessionLength: 0.0,
        completionRate: 0.0,
        mostBlockedApps: [],
        appBlockCounts: {},
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    final completedSessions = periodSessions.where((s) => s.status == SessionStatus.completed).toList();
    final cancelledSessions = periodSessions.where((s) => s.status == SessionStatus.cancelled).toList();
    
    int totalFocusMinutes = 0;
    int totalPauseMinutes = 0;
    final appBlockCounts = <String, int>{};

    for (final session in periodSessions) {
      final actualFocusTime = session.calculateActualFocusTime();
      totalFocusMinutes += actualFocusTime;
      totalPauseMinutes += session.totalPauseTimeMinutes;

      for (final app in session.blockedApps) {
        appBlockCounts[app] = (appBlockCounts[app] ?? 0) + 1;
      }
    }

    final averageSessionLength = periodSessions.map((s) => s.durationMinutes).reduce((a, b) => a + b) / periodSessions.length;
    final completionRate = completedSessions.length / periodSessions.length;

    final sortedApps = appBlockCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostBlockedApps = sortedApps.take(5).map((e) => e.key).toList();

    return SessionStatistics(
      sessionId: periodSessions.last.id,
      totalFocusMinutes: totalFocusMinutes,
      totalPauseMinutes: totalPauseMinutes,
      totalSessions: periodSessions.length,
      completedSessions: completedSessions.length,
      cancelledSessions: cancelledSessions.length,
      averageSessionLength: averageSessionLength,
      completionRate: completionRate,
      mostBlockedApps: mostBlockedApps,
      appBlockCounts: appBlockCounts,
      lastSessionDate: periodSessions.last.startTime,
      currentStreak: 0, // Would need separate calculation for period
      longestStreak: 0, // Would need separate calculation for period
    );
  }

  // Get today's statistics
  SessionStatistics getTodayStatistics() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getStatisticsForPeriod(startOfDay, endOfDay);
  }

  // Get this week's statistics
  SessionStatistics getThisWeekStatistics() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return getStatisticsForPeriod(startOfWeek, endOfWeek);
  }

  // Get this month's statistics
  SessionStatistics getThisMonthStatistics() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return getStatisticsForPeriod(startOfMonth, endOfMonth);
  }

  // Get session history for specific session
  List<SessionHistory> getSessionHistory(String sessionId) {
    return _history.where((entry) => entry.sessionId == sessionId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get recent activity
  List<SessionHistory> getRecentActivity({int limit = 20}) {
    final sortedHistory = List<SessionHistory>.from(_history)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedHistory.take(limit).toList();
  }

  // Update sessions list
  Future<void> updateSessions(List<FocusSession> sessions) async {
    print('StatisticsService: updateSessions - sessions count: ${sessions.length}');
    _sessions = sessions;
    await _calculateStatistics();
    print('StatisticsService: updateSessions - completed');
    notifyListeners();
  }

  // Add new session
  Future<void> addSession(FocusSession session) async {
    _sessions.add(session);
    await _calculateStatistics();
    notifyListeners();
  }

  // Update session
  Future<void> updateSession(FocusSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      await _calculateStatistics();
      notifyListeners();
    }
  }

  // Get productivity insights
  Map<String, dynamic> getProductivityInsights() {
    if (_currentStatistics == null) return {};

    final insights = <String, dynamic>{};
    
    // Focus efficiency
    if (_currentStatistics!.totalSessions > 0) {
      final efficiency = (_currentStatistics!.completedSessions / _currentStatistics!.totalSessions) * 100;
      insights['focusEfficiency'] = efficiency.round();
    }

    // Average session length
    insights['averageSessionLength'] = _currentStatistics!.averageSessionLength.round();

    // Most productive time
    final timeSlots = <int, int>{};
    for (final session in _sessions) {
      final hour = session.startTime.hour;
      timeSlots[hour] = (timeSlots[hour] ?? 0) + 1;
    }
    
    if (timeSlots.isNotEmpty) {
      final mostProductiveHour = timeSlots.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insights['mostProductiveHour'] = mostProductiveHour;
    }

    // Streak information
    insights['currentStreak'] = _currentStatistics!.currentStreak;
    insights['longestStreak'] = _currentStatistics!.longestStreak;

    return insights;
  }

  // Clear all data
  Future<void> clearAllData() async {
    _sessions.clear();
    _history.clear();
    _currentStatistics = null;
    await _storageService.clearAllData();
    notifyListeners();
  }

  // Clean up duplicate history entries
  Future<void> cleanupDuplicateHistory() async {
    final uniqueEntries = <String, SessionHistory>{};
    
    for (final entry in _history) {
      final key = '${entry.sessionId}_${entry.action.name}_${entry.timestamp.millisecondsSinceEpoch ~/ 1000}';
      if (!uniqueEntries.containsKey(key)) {
        uniqueEntries[key] = entry;
      }
    }
    
    _history = uniqueEntries.values.toList();
    await _storageService.saveSessionHistory(_history);
    notifyListeners();
  }

  // Debug: Print current history
  void debugPrintHistory() {
    print('=== DEBUG: Current History ===');
    for (final entry in _history) {
      print('${entry.timestamp}: ${entry.action.name} - ${entry.note}');
    }
    print('=== END DEBUG ===');
  }
} 