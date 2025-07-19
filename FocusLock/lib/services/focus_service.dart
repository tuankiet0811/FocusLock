import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../models/session_history.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'app_blocking_service.dart';
import 'statistics_service.dart';

class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AppBlockingService _appBlockingService = AppBlockingService();
  final StatisticsService _statisticsService = StatisticsService();

  FocusSession? _currentSession;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  List<AppInfo> _blockedApps = [];
  List<FocusSession> _sessions = [];
  bool _isStartingSession = false; // Để ngăn chặn việc gọi startSession nhiều lần
  String? _lastSessionId; // Để track session cuối cùng được tạo
  DateTime? _lastStartTime; // Để track thời gian bắt đầu cuối cùng

  // Getters
  FocusSession? get currentSession => _currentSession;
  int get remainingSeconds => _remainingSeconds;
  bool get isActive => _isActive;
  List<AppInfo> get blockedApps => _blockedApps;
  List<FocusSession> get sessions => _sessions;

  // Initialize service
  Future<void> init() async {
    await _storageService.init();
    await _notificationService.init();
    await _appBlockingService.init();
    await _statisticsService.init();
    
    _blockedApps = await _storageService.getBlockedApps();
    
    // If no blocked apps are set, add some default social media apps
    if (_blockedApps.isEmpty) {
      _blockedApps = [
        AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook', isBlocked: true),
        AppInfo(packageName: 'com.instagram.android', appName: 'Instagram', isBlocked: true),
        AppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp', isBlocked: true),
        AppInfo(packageName: 'com.google.android.youtube', appName: 'YouTube', isBlocked: true),
        AppInfo(packageName: 'com.twitter.android', appName: 'Twitter/X', isBlocked: true),
        AppInfo(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok', isBlocked: true),
      ];
      await _storageService.saveBlockedApps(_blockedApps);
    }
    
    _sessions = await _storageService.getFocusSessions();
    await _statisticsService.updateSessions(_sessions);
    
    // Check if there's an active session
    final activeSession = _sessions.where((session) => session.isActive).firstOrNull;
    if (activeSession != null) {
      await _resumeSession(activeSession);
    }
    
    notifyListeners();
  }

  // Start a new focus session
  Future<void> startSession({required int durationMinutes, String? goal}) async {
    print('FocusService: Bắt đầu startSession - duration: $durationMinutes, goal: $goal');
    
    // Ngăn chặn việc gọi startSession nhiều lần
    if (_isStartingSession) {
      print('FocusService: Đang trong quá trình bắt đầu session, bỏ qua');
      return;
    }
    
    // Kiểm tra xem đã có session đang chạy hoặc đang pause không
    if (_currentSession != null && 
        (_currentSession!.status == SessionStatus.running || 
         _currentSession!.status == SessionStatus.paused)) {
      print('FocusService: Đã có session đang hoạt động, bỏ qua');
      return;
    }
    
    _isStartingSession = true;
    
    try {
      // Đảm bảo dừng session cũ nếu có
      if (_isActive || _currentSession != null) {
        print('FocusService: Dừng session cũ trước khi bắt đầu session mới');
        await stopSession(silent: true); // Không tạo history entry khi dừng để bắt đầu session mới
      }

    final now = DateTime.now();
    final durationSeconds = durationMinutes * 60;
    final sessionId = Helpers.generateId();
    
    // Kiểm tra xem có session nào được tạo trong 5 giây gần đây không
    if (_lastStartTime != null && now.difference(_lastStartTime!).inSeconds < 5) {
      print('FocusService: Session đã được tạo trong 5 giây gần đây, bỏ qua');
      return;
    }
    
    // Kiểm tra xem session này đã được tạo chưa
    if (_lastSessionId != null && _sessions.any((s) => s.id == _lastSessionId)) {
      print('FocusService: Session đã được tạo trước đó, bỏ qua');
      return;
    }
    
    _currentSession = FocusSession(
      id: sessionId,
      startTime: now,
      endTime: null, // Sẽ cập nhật khi kết thúc
      durationMinutes: durationMinutes,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isActive: true,
      blockedApps: _blockedApps.where((app) => app.isBlocked).map((app) => app.packageName).toList(),
      goal: goal,
      pausedTime: null,
      status: SessionStatus.running,
      lastActivityTime: now,
    );
    
    _lastSessionId = sessionId;
    _lastStartTime = now;

    _remainingSeconds = durationSeconds;
    _isActive = true;

    // Save session
    await _storageService.addFocusSession(_currentSession!);
    _sessions.add(_currentSession!);
    await _statisticsService.addSession(_currentSession!);

    // Add history entry
    await _statisticsService.addHistoryEntry(
      sessionId: _currentSession!.id,
      action: SessionAction.started,
      data: {
        'durationMinutes': durationMinutes,
        'goal': goal,
        'blockedApps': _currentSession!.blockedApps,
      },
      note: goal != null ? 'Bắt đầu phiên tập trung với mục tiêu: $goal' : 'Bắt đầu phiên tập trung',
    );

    // Start timer
    _startTimer();

    // Start app blocking
    await _appBlockingService.startBlocking(_blockedApps);

    // Show notification
    await _notificationService.showFocusStartNotification(
      durationMinutes: durationMinutes,
      goal: goal,
    );

    print('FocusService: Đã hoàn thành startSession');
    
    // Auto cleanup duplicates sau khi tạo session
    await autoCleanupDuplicates();
    
    notifyListeners();
    } finally {
      _isStartingSession = false;
    }
  }

  // Stop current session
  Future<void> stopSession({bool completed = false, bool silent = false}) async {
    print('FocusService: Bắt đầu stopSession, completed: $completed, silent: $silent');
    if (_currentSession == null) {
      print('FocusService: Không có session hiện tại');
      return;
    }
    print('FocusService: Session status: ${_currentSession!.status}');

    _timer?.cancel();
    _timer = null;

    final now = DateTime.now();
    final actualFocusMinutes = _currentSession!.calculateActualFocusTime();
    print('FocusService: stopSession - actualFocusMinutes: $actualFocusMinutes');
    final status = completed ? SessionStatus.completed : SessionStatus.cancelled;
    
    // Update session
    _currentSession = _currentSession!.copyWith(
      isActive: false,
      endTime: now,
      pausedTime: null,
      remainingSeconds: null,
      actualFocusMinutes: actualFocusMinutes,
      status: status,
      lastActivityTime: now,
    );

    // Update in storage and statistics
    await _storageService.updateFocusSession(_currentSession!);
    await _statisticsService.updateSession(_currentSession!);
    
    final index = _sessions.indexWhere((session) => session.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = _currentSession!;
    }

    // Add history entry only if not silent
    if (!silent) {
      await _statisticsService.addHistoryEntry(
        sessionId: _currentSession!.id,
        action: completed ? SessionAction.completed : SessionAction.cancelled,
        data: {
          'actualFocusMinutes': actualFocusMinutes,
          'durationMinutes': _currentSession!.durationMinutes,
          'completionPercentage': _currentSession!.calculateCompletionPercentage(),
        },
        note: completed 
            ? 'Hoàn thành phiên tập trung thành công!'
            : 'Hủy bỏ phiên tập trung',
      );
    }

    // Stop app blocking
    await _appBlockingService.stopBlocking();

    // Show notification only if not silent
    if (!silent) {
      await _notificationService.showFocusEndNotification(
        durationMinutes: _currentSession!.durationMinutes,
        completed: completed,
        goal: _currentSession!.goal,
      );
    }

    _isActive = false;
    _currentSession = null;
    _remainingSeconds = 0;
    _lastSessionId = null; // Reset session ID
    _lastStartTime = null; // Reset start time

    print('FocusService: Đã hoàn thành stopSession');
    notifyListeners();
  }

  // Pause session
  Future<void> pauseSession() async {
    if (_currentSession == null || _currentSession!.status == SessionStatus.paused) return;
    
    final now = DateTime.now();
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    
    // Create pause history entry
    final pauseEntry = SessionPause(
      pauseTime: now,
      durationMinutes: 0, // Sẽ cập nhật khi resume
    );
    
    final updatedPauseHistory = List<SessionPause>.from(_currentSession!.pauseHistory)
      ..add(pauseEntry);
    
    _currentSession = _currentSession!.copyWith(
      pausedTime: now,
      remainingSeconds: _remainingSeconds,
      status: SessionStatus.paused,
      pauseHistory: updatedPauseHistory,
      lastActivityTime: now,
    );
    
    await _storageService.updateFocusSession(_currentSession!);
    await _statisticsService.updateSession(_currentSession!);
    
    // Add history entry
    await _statisticsService.addHistoryEntry(
      sessionId: _currentSession!.id,
      action: SessionAction.paused,
      data: {
        'remainingSeconds': _remainingSeconds,
      },
      note: 'Tạm dừng phiên tập trung',
    );
    
    notifyListeners();
  }

  // Resume session
  Future<void> resumeSession() async {
    if (_currentSession == null || _currentSession!.status != SessionStatus.paused) return;
    
    final now = DateTime.now();
    _isActive = true;
    _remainingSeconds = _currentSession!.remainingSeconds ?? _remainingSeconds;
    
    print('FocusService: Resume session - pauseTime: ${_currentSession!.pausedTime}, now: $now');
    
    // Update last pause entry with resume time and calculate total pause time
    final updatedPauseHistory = List<SessionPause>.from(_currentSession!.pauseHistory);
    int totalPauseTimeMinutes = _currentSession!.totalPauseTimeMinutes;
    
    if (updatedPauseHistory.isNotEmpty) {
      final lastPause = updatedPauseHistory.last;
      // Tính thời gian pause chính xác hơn bằng giây rồi chuyển sang phút
      final pauseDurationSeconds = now.difference(lastPause.pauseTime).inSeconds;
      final pauseDurationMinutes = (pauseDurationSeconds / 60).ceil(); // Làm tròn lên
      print('FocusService: Pause duration: ${pauseDurationSeconds}s = ${pauseDurationMinutes}m');
      
      final updatedPause = SessionPause(
        pauseTime: lastPause.pauseTime,
        resumeTime: now,
        durationMinutes: pauseDurationMinutes,
      );
      updatedPauseHistory[updatedPauseHistory.length - 1] = updatedPause;
      totalPauseTimeMinutes += pauseDurationMinutes;
      print('FocusService: Total pause time: $totalPauseTimeMinutes minutes');
    }
    
    _currentSession = _currentSession!.copyWith(
      pausedTime: null,
      remainingSeconds: null,
      status: SessionStatus.running,
      pauseHistory: updatedPauseHistory,
      totalPauseTimeMinutes: totalPauseTimeMinutes,
      lastActivityTime: now,
    );
    
    await _storageService.updateFocusSession(_currentSession!);
    await _statisticsService.updateSession(_currentSession!);
    
    // Add history entry
    await _statisticsService.addHistoryEntry(
      sessionId: _currentSession!.id,
      action: SessionAction.resumed,
      data: {
        'remainingSeconds': _remainingSeconds,
      },
      note: 'Tiếp tục phiên tập trung',
    );
    
    _startTimer();
    notifyListeners();
  }

  // Resume session from storage
  Future<void> _resumeSession(FocusSession session) async {
    _currentSession = session;
    _isActive = session.isActive;
    
    if (_isActive) {
      if (session.status == SessionStatus.paused && session.remainingSeconds != null) {
        // Đang pause, khôi phục đúng trạng thái
        _remainingSeconds = session.remainingSeconds!;
        // Không chạy timer, chỉ notify để UI hiển thị đúng
        notifyListeners();
      } else if (session.status == SessionStatus.running) {
        final now = DateTime.now();
        final expectedEndTime = session.startTime.add(Duration(minutes: session.durationMinutes));
      
        if (now.isBefore(expectedEndTime)) {
          _remainingSeconds = expectedEndTime.difference(now).inSeconds;
          _startTimer();
        } else {
          // Session has expired - sử dụng silent để tránh tạo history entry
          await stopSession(completed: true, silent: true);
        }
      }
    }
  }

  // Start timer
  void _startTimer() {
    _timer?.cancel(); // Đảm bảo không có timer cũ chạy song song
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        
        // Show motivational notification at certain intervals
        final percentage = getCompletionPercentage();
        
        if (_remainingSeconds % 300 == 0 && _remainingSeconds > 0) { // Every 5 minutes
          _notificationService.showMotivationalNotification(
            completionPercentage: percentage,
            remainingMinutes: _remainingSeconds ~/ 60,
          );
        }
        
        notifyListeners();
      } else {
        timer.cancel();
        // Kiểm tra xem session có còn tồn tại không trước khi gọi stopSession
        if (_currentSession != null && _isActive) {
          stopSession(completed: true);
        }
      }
    });
  }

  // Update blocked apps
  Future<void> updateBlockedApps(List<AppInfo> apps) async {
    final previousBlockedApps = _blockedApps.where((app) => app.isBlocked).map((app) => app.packageName).toSet();
    final newBlockedApps = apps.where((app) => app.isBlocked).map((app) => app.packageName).toSet();
    
    _blockedApps = apps;
    await _storageService.saveBlockedApps(apps);
    
    // Update current session if active
    if (_currentSession != null && _isActive) {
      _currentSession = _currentSession!.copyWith(
        blockedApps: apps.where((app) => app.isBlocked).map((app) => app.packageName).toList(),
        lastActivityTime: DateTime.now(),
      );
      await _storageService.updateFocusSession(_currentSession!);
      await _statisticsService.updateSession(_currentSession!);
      
      // Track app blocking changes
      final newlyBlocked = newBlockedApps.difference(previousBlockedApps);
      final newlyUnblocked = previousBlockedApps.difference(newBlockedApps);
      
      for (final app in newlyBlocked) {
        await _statisticsService.addHistoryEntry(
          sessionId: _currentSession!.id,
          action: SessionAction.appBlocked,
          data: {'app': app},
          note: 'Chặn ứng dụng: $app',
        );
      }
      
      for (final app in newlyUnblocked) {
        await _statisticsService.addHistoryEntry(
          sessionId: _currentSession!.id,
          action: SessionAction.appUnblocked,
          data: {'app': app},
          note: 'Bỏ chặn ứng dụng: $app',
        );
      }
    }
    
    notifyListeners();
  }

  // Check if app is blocked
  bool isAppBlocked(String packageName) {
    if (!_isActive) return false;
    
    return _blockedApps.any((app) => 
      app.packageName == packageName && app.isBlocked
    );
  }

  // Get blocked app info
  AppInfo? getBlockedAppInfo(String packageName) {
    return _blockedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => AppInfo(
        packageName: packageName,
        appName: packageName,
        isBlocked: false,
      ),
    );
  }

  // Get today's focus time
  int getTodayFocusTime() {
    final todayStats = _statisticsService.getTodayStatistics();
    return todayStats.totalFocusMinutes;
  }

  // Get this week's focus time
  int getThisWeekFocusTime() {
    final weekStats = _statisticsService.getThisWeekStatistics();
    return weekStats.totalFocusMinutes;
  }

  // Get completion percentage
  double getCompletionPercentage() {
    if (_currentSession == null) return 0.0;
    return _currentSession!.calculateCompletionPercentage();
  }

  // Get current statistics
  SessionStatistics? getCurrentStatistics() {
    return _statisticsService.currentStatistics;
  }

  // Get session history
  List<SessionHistory> getSessionHistory(String sessionId) {
    return _statisticsService.getSessionHistory(sessionId);
  }

  // Get recent activity
  List<SessionHistory> getRecentActivity({int limit = 20}) {
    return _statisticsService.getRecentActivity(limit: limit);
  }

  // Get productivity insights
  Map<String, dynamic> getProductivityInsights() {
    return _statisticsService.getProductivityInsights();
  }

  // Clean up duplicate sessions
  Future<void> cleanupDuplicateSessions() async {
    print('FocusService: Bắt đầu cleanup duplicate sessions');
    
    final uniqueSessions = <String, FocusSession>{};
    final sessionsToRemove = <FocusSession>[];
    
    for (final session in _sessions) {
      // Sử dụng thời gian bắt đầu chính xác hơn
      final key = '${session.startTime.millisecondsSinceEpoch}_${session.durationMinutes}_${session.goal ?? ""}';
      
      if (uniqueSessions.containsKey(key)) {
        // Nếu session này trùng lặp, thêm vào danh sách xóa
        sessionsToRemove.add(session);
        print('FocusService: Phát hiện session trùng lặp: ${session.id} - startTime: ${session.startTime}');
      } else {
        uniqueSessions[key] = session;
      }
    }
    
    // Xóa sessions trùng lặp
    for (final session in sessionsToRemove) {
      _sessions.remove(session);
      await _storageService.removeFocusSession(session.id);
      print('FocusService: Đã xóa session trùng lặp: ${session.id}');
    }
    
    // Cập nhật statistics
    await _statisticsService.updateSessions(_sessions);
    notifyListeners();
    
    print('FocusService: Đã cleanup ${sessionsToRemove.length} sessions trùng lặp');
  }

  // Auto cleanup duplicate sessions
  Future<void> autoCleanupDuplicates() async {
    print('FocusService: Auto cleanup duplicates');
    
    final now = DateTime.now();
    final recentSessions = _sessions.where((session) => 
      now.difference(session.startTime).inSeconds < 10 // Sessions trong 10 giây gần đây
    ).toList();
    
    if (recentSessions.length > 1) {
      print('FocusService: Phát hiện ${recentSessions.length} sessions gần đây, cleanup...');
      await cleanupDuplicateSessions();
    }
  }

  // Dispose
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 