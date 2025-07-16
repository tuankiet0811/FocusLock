import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'app_blocking_service.dart';

class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AppBlockingService _appBlockingService = AppBlockingService();

  FocusSession? _currentSession;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  List<AppInfo> _blockedApps = [];
  List<FocusSession> _sessions = [];

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
    
    // Check if there's an active session
    final activeSession = _sessions.where((session) => session.isActive).firstOrNull;
    if (activeSession != null) {
      await _resumeSession(activeSession);
    }
    
    notifyListeners();
  }

  // Start a new focus session
  Future<void> startSession({required int durationMinutes, String? goal}) async {
    if (_isActive) {
      await stopSession();
    }

    final now = DateTime.now();
    final durationSeconds = durationMinutes * 60;
    _currentSession = FocusSession(
      id: Helpers.generateId(),
      startTime: now,
      endTime: now.add(Duration(seconds: durationSeconds)),
      durationMinutes: durationMinutes,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isActive: true,
      blockedApps: _blockedApps.where((app) => app.isBlocked).map((app) => app.packageName).toList(),
      goal: goal,
      pausedTime: null,
    );

    _remainingSeconds = durationSeconds;
    _isActive = true;

    // Save session
    await _storageService.addFocusSession(_currentSession!);
    _sessions.add(_currentSession!);

    // Start timer
    _startTimer();

    // Start app blocking
    await _appBlockingService.startBlocking(_blockedApps);

    // Show notification
    await _notificationService.showFocusStartNotification(
      durationMinutes: durationMinutes,
      goal: goal,
    );

    notifyListeners();
  }

  // Stop current session
  Future<void> stopSession({bool completed = false}) async {
    if (!_isActive || _currentSession == null) return;

    _timer?.cancel();
    _timer = null;

    // Update session
    _currentSession = _currentSession!.copyWith(
      isActive: false,
      endTime: DateTime.now(),
      pausedTime: null,
      remainingSeconds: null,
    );

    // Update in storage
    await _storageService.updateFocusSession(_currentSession!);
    
    final index = _sessions.indexWhere((session) => session.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = _currentSession!;
    }

    // Stop app blocking
    await _appBlockingService.stopBlocking();

    // Update statistics
    await _updateStatistics(completed);

    // Show notification
    await _notificationService.showFocusEndNotification(
      durationMinutes: _currentSession!.durationMinutes,
      completed: completed,
      goal: _currentSession!.goal,
    );

    _isActive = false;
    _currentSession = null;
    _remainingSeconds = 0;

    notifyListeners();
  }

  // Pause session
  Future<void> pauseSession() async {
    if (_currentSession == null) return;
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _currentSession = _currentSession!.copyWith(
      pausedTime: DateTime.now(),
      remainingSeconds: _remainingSeconds,
    );
    await _storageService.updateFocusSession(_currentSession!);
    notifyListeners();
  }

  // Resume session
  Future<void> resumeSession() async {
    if (_currentSession == null) return;
    _isActive = true;
    _remainingSeconds = _currentSession!.remainingSeconds ?? _remainingSeconds;
    // XÓA pausedTime và remainingSeconds
    _currentSession = _currentSession!.copyWith(
      pausedTime: null,
      remainingSeconds: null,
    );
    await _storageService.updateFocusSession(_currentSession!);
    _startTimer();
    notifyListeners();
  }

  // Resume session from storage
  Future<void> _resumeSession(FocusSession session) async {
    _currentSession = session;
    _isActive = session.isActive;
    
    if (_isActive) {
      if (session.pausedTime != null && session.remainingSeconds != null) {
        // Đang pause, khôi phục đúng trạng thái
        _remainingSeconds = session.remainingSeconds!;
        // Không chạy timer, chỉ notify để UI hiển thị đúng
        notifyListeners();
      } else {
        final now = DateTime.now();
        final endTime = session.endTime;
      
        if (now.isBefore(endTime)) {
          _remainingSeconds = endTime.difference(now).inSeconds;
          _startTimer();
        } else {
          // Session has expired
          await stopSession(completed: true);
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
        stopSession(completed: true);
      }
    });
  }

  // Update blocked apps
  Future<void> updateBlockedApps(List<AppInfo> apps) async {
    _blockedApps = apps;
    await _storageService.saveBlockedApps(apps);
    
    // Update current session if active
    if (_currentSession != null && _isActive) {
      _currentSession = _currentSession!.copyWith(
        blockedApps: apps.where((app) => app.isBlocked).map((app) => app.packageName).toList(),
      );
      await _storageService.updateFocusSession(_currentSession!);
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

  // Update statistics
  Future<void> _updateStatistics(bool completed) async {
    final statistics = await _storageService.getStatistics();
    
    int totalFocusTime = statistics['total_focus_time'] ?? 0;
    int totalSessions = statistics['total_sessions'] ?? 0;
    int completedSessions = statistics['completed_sessions'] ?? 0;
    int currentStreak = statistics['current_streak'] ?? 0;
    int longestStreak = statistics['longest_streak'] ?? 0;
    
    totalFocusTime += _currentSession!.durationMinutes;
    totalSessions++;
    
    if (completed) {
      completedSessions++;
      currentStreak++;
      
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      currentStreak = 0;
    }
    
    await _storageService.updateStatistics(
      totalFocusTime: totalFocusTime,
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: DateTime.now(),
    );
  }

  // Get today's focus time
  int getTodayFocusTime() {
    final todaySessions = Helpers.getTodaySessions(_sessions.map((s) => s.toJson()).toList());
    return Helpers.calculateTotalFocusTime(todaySessions);
  }

  // Get this week's focus time
  int getThisWeekFocusTime() {
    final weekSessions = Helpers.getThisWeekSessions(_sessions.map((s) => s.toJson()).toList());
    return Helpers.calculateTotalFocusTime(weekSessions);
  }

  // Get completion percentage
  double getCompletionPercentage() {
    if (_currentSession == null) return 0.0;
    final total = _currentSession!.durationSeconds;
    return 1 - (_remainingSeconds / total);
  }

  // Dispose
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 