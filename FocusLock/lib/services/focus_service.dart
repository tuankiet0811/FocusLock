import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';
import '../models/app_info.dart';
import '../models/session_history.dart';
import '../models/session_status.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'hybrid_storage_service.dart';
import 'notification_service.dart';
import 'app_blocking_service.dart';
import 'statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // Added import for AuthService
import 'firebase_storage_service.dart'; // Added import for FirebaseStorageService

class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final HybridStorageService _storageService = HybridStorageService();
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
  
  // Check if any apps are selected for blocking
  bool get hasSelectedApps => _blockedApps.any((app) => app.isBlocked);
  
  // Get selected apps for blocking
  List<AppInfo> get selectedApps => _blockedApps.where((app) => app.isBlocked).toList();

  // Initialize service
  Future<void> init() async {
    print('FocusService: Bắt đầu khởi tạo...');
    
    await _storageService.init();
    print('FocusService: StorageService đã khởi tạo');
    
    await _notificationService.init();
    print('FocusService: NotificationService đã khởi tạo');
    
    await _appBlockingService.init();
    print('FocusService: AppBlockingService đã khởi tạo');
    
    await _statisticsService.init();
    print('FocusService: StatisticsService đã khởi tạo');
    
    _blockedApps = await _storageService.getBlockedApps();
    print('FocusService: Loaded ${_blockedApps.length} blocked apps');
    
    // If no blocked apps are set, add some default social media apps (but not blocked by default)
    if (_blockedApps.isEmpty) {
      print('FocusService: No blocked apps found, adding defaults (not blocked)');
      _blockedApps = [
        AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook', isBlocked: false),
        AppInfo(packageName: 'com.instagram.android', appName: 'Instagram', isBlocked: false),
        AppInfo(packageName: 'com.whatsapp', appName: 'WhatsApp', isBlocked: false),
        AppInfo(packageName: 'com.google.android.youtube', appName: 'YouTube', isBlocked: false),
        AppInfo(packageName: 'com.twitter.android', appName: 'Twitter/X', isBlocked: false),
        AppInfo(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok', isBlocked: false),
        AppInfo(packageName: 'com.telegram.messenger', appName: 'Telegram', isBlocked: false),
        AppInfo(packageName: 'com.discord', appName: 'Discord', isBlocked: false),
        AppInfo(packageName: 'com.reddit.frontpage', appName: 'Reddit', isBlocked: false),
        AppInfo(packageName: 'com.pinterest', appName: 'Pinterest', isBlocked: false),
        AppInfo(packageName: 'com.linkedin.android', appName: 'LinkedIn', isBlocked: false),
        AppInfo(packageName: 'com.spotify.music', appName: 'Spotify', isBlocked: false),
        AppInfo(packageName: 'com.netflix.mediaclient', appName: 'Netflix', isBlocked: false),
      ];
      await _storageService.saveBlockedApps(_blockedApps);
      print('FocusService: Saved default apps (not blocked by default)');
    }
    
    _sessions = await _storageService.getFocusSessions();
    print('FocusService: Loaded ${_sessions.length} sessions from storage');
    
    // Auto fix sessions nếu cần khi khởi động
    await _autoFixSessionsIfNeeded();
    
    await _statisticsService.updateSessions(_sessions);
    print('FocusService: Updated statistics with ${_sessions.length} sessions');
    
    // Check if there's an active session
    final activeSession = _sessions.where((session) => session.isActive).firstOrNull;
    if (activeSession != null) {
      print('FocusService: Found active session ${activeSession.id}, resuming...');
      await _resumeSession(activeSession);
    } else {
      print('FocusService: No active session found');
      
      // Try to restore from timer state as backup
      await _restoreTimerState();
    }
    
    print('FocusService: Khởi tạo hoàn tất');
    
    // Auto restore connection state
    await checkAndRestoreConnection();
    
    // Restore timer state
    await _restoreTimerState();
    
    notifyListeners();
  }

  // Auto fix sessions nếu cần khi khởi động
  Future<void> _autoFixSessionsIfNeeded() async {
    print('FocusService: Kiểm tra và auto fix sessions nếu cần');
    print('FocusService: Tổng số sessions: ${_sessions.length}');
    
    bool hasFixed = false;
    for (int i = 0; i < _sessions.length; i++) {
      final session = _sessions[i];
      print('FocusService: Kiểm tra session ${i + 1}/${_sessions.length} - ID: ${session.id}, Status: ${session.status}');
      
      // Chỉ fix các session đã hoàn thành hoặc bị hủy
      if (session.status == SessionStatus.completed || session.status == SessionStatus.cancelled) {
        final calculatedActualTime = session.calculateActualFocusTime();
        print('FocusService: Session ${session.id} - actualFocusMinutes: ${session.actualFocusMinutes}, calculated: $calculatedActualTime');
        
        // Kiểm tra nếu actualFocusMinutes không chính xác hoặc null
        if (session.actualFocusMinutes == null || session.actualFocusMinutes != calculatedActualTime) {
          print('FocusService: Auto fix session ${session.id} - old: ${session.actualFocusMinutes}, new: $calculatedActualTime');
          
          final fixedSession = session.copyWith(
            actualFocusMinutes: calculatedActualTime,
          );
          
          _sessions[i] = fixedSession;
          await _storageService.updateFocusSession(fixedSession);
          hasFixed = true;
        }
      }
    }
    
    if (hasFixed) {
      print('FocusService: Đã auto fix sessions');
    } else {
      print('FocusService: Không cần auto fix sessions');
    }
    
    print('FocusService: Kết thúc auto fix - Tổng số sessions: ${_sessions.length}');
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
      
      // Auto save timer state
      await autoSaveTimerState();
      
      // Auto save session state immediately
      await autoSaveSessionState();

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

      // Start app blocking - chỉ chặn những app có isBlocked = true
      final appsToBlock = _blockedApps.where((app) => app.isBlocked).toList();
      print('FocusService: Starting blocking for ${appsToBlock.length} selected apps');
      if (appsToBlock.isNotEmpty) {
        print('FocusService: Apps to block: ${appsToBlock.map((app) => '${app.appName} (${app.packageName})').join(', ')}');
      } else {
        print('FocusService: No apps selected for blocking');
      }
      await _appBlockingService.startBlocking(appsToBlock);

      // Show notification
      await _notificationService.showFocusStartNotification(
        durationMinutes: durationMinutes,
        goal: goal,
      );

      // Thông báo nếu chưa chọn app nào để chặn
      if (appsToBlock.isEmpty) {
        print('FocusService: Warning - No apps selected for blocking');
        // Gửi event để UI có thể hiển thị thông báo
        notifyListeners();
      }

      print('FocusService: Đã hoàn thành startSession');
      
      // Auto cleanup duplicates sau khi tạo session
      await autoCleanupDuplicates();
      
      notifyListeners();
    } catch (e) {
      print('FocusService: Lỗi trong startSession: $e');
      // Reset state nếu có lỗi
      _isActive = false;
      _currentSession = null;
      _remainingSeconds = 0;
      _timer?.cancel();
      _timer = null;
      _lastSessionId = null;
      _lastStartTime = null;
      
      // Đảm bảo dừng app blocking nếu đã bắt đầu
      await _appBlockingService.stopBlocking();
      
      // Hủy thông báo nếu đã hiển thị
      await _notificationService.cancelFocusProgressNotification();
      
      notifyListeners();
      
      // Re-throw để UI có thể hiển thị lỗi nếu cần
      rethrow;
    } finally {
      _isStartingSession = false;
    }
  }

  // Stop current session
  Future<void> stopSession({bool completed = false, bool silent = false}) async {
    print('FocusService: Bắt đầu stopSession, completed: $completed, silent: $silent');
    
    try {
      if (_currentSession == null) {
        print('FocusService: Không có session hiện tại');
        return;
      }
      
      print('FocusService: Session status: ${_currentSession!.status}');

      _timer?.cancel();
      _timer = null;
      
      // Hủy thông báo liên tục
      await _notificationService.cancelFocusProgressNotification();

      final now = DateTime.now();
      
      // Tính toán actualFocusMinutes chính xác
      int actualFocusMinutes = 0; // Khởi tạo mặc định
      if (_currentSession!.status == SessionStatus.completed) {
        // Nếu session đã completed, sử dụng giá trị đã lưu
        actualFocusMinutes = _currentSession!.actualFocusMinutes ?? 0;
      } else {
        // Tính toán lại actualFocusMinutes
        actualFocusMinutes = _currentSession!.calculateActualFocusTime();
      }
      
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
      
      // Clear timer state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timer_remaining_seconds');
      await prefs.remove('timer_session_id');
      await prefs.remove('timer_is_active');

      print('FocusService: Đã hoàn thành stopSession');
      notifyListeners();
      
    } catch (e) {
      print('FocusService: Lỗi trong stopSession: $e');
      // Đảm bảo hủy thông báo ngay cả khi có lỗi
      await _notificationService.cancelFocusProgressNotification();
      // Đảm bảo reset state ngay cả khi có lỗi
      _isActive = false;
      _currentSession = null;
      _remainingSeconds = 0;
      _timer?.cancel();
      _timer = null;
      notifyListeners();
    }
  }

  // Pause session
  Future<void> pauseSession() async {
    if (_currentSession == null || _currentSession!.status == SessionStatus.paused) return;
    
    final now = DateTime.now();
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    
    // Tính toán actualFocusMinutes trước khi pause
    final actualFocusMinutes = _currentSession!.calculateActualFocusTime();
    print('FocusService: Actual focus minutes before pause: $actualFocusMinutes');
    
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
      actualFocusMinutes: actualFocusMinutes, // Cập nhật actualFocusMinutes
      lastActivityTime: now,
    );
    
    await _storageService.updateFocusSession(_currentSession!);
    await _statisticsService.updateSession(_currentSession!);
    
    // Auto save timer state
    await autoSaveTimerState();
    
    // Add history entry
    await _statisticsService.addHistoryEntry(
      sessionId: _currentSession!.id,
      action: SessionAction.paused,
      data: {
        'remainingSeconds': _remainingSeconds,
        'actualFocusMinutes': actualFocusMinutes,
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
    
    // Update last pause entry with resume time
    final updatedPauseHistory = List<SessionPause>.from(_currentSession!.pauseHistory);
    
    if (updatedPauseHistory.isNotEmpty) {
      final lastPause = updatedPauseHistory.last;
      // Tính thời gian pause chính xác bằng giây
      final pauseDurationSeconds = now.difference(lastPause.pauseTime).inSeconds;
      final pauseDurationMinutes = (pauseDurationSeconds / 60).ceil(); // Làm tròn lên
      print('FocusService: Pause duration: ${pauseDurationSeconds}s = ${pauseDurationMinutes}m');
      
      final updatedPause = SessionPause(
        pauseTime: lastPause.pauseTime,
        resumeTime: now,
        durationMinutes: pauseDurationMinutes,
      );
      updatedPauseHistory[updatedPauseHistory.length - 1] = updatedPause;
    }
    
    // Tính toán lại actualFocusMinutes trước khi cập nhật session
    final actualFocusMinutes = _currentSession!.calculateActualFocusTime();
    print('FocusService: Actual focus minutes after resume: $actualFocusMinutes');
    
    _currentSession = _currentSession!.copyWith(
      pausedTime: null,
      remainingSeconds: null,
      status: SessionStatus.running,
      pauseHistory: updatedPauseHistory,
      actualFocusMinutes: actualFocusMinutes, // Cập nhật actualFocusMinutes
      lastActivityTime: now,
    );
    
    await _storageService.updateFocusSession(_currentSession!);
    await _statisticsService.updateSession(_currentSession!);
    
    // Auto save timer state
    await autoSaveTimerState();
    
    // Add history entry
    await _statisticsService.addHistoryEntry(
      sessionId: _currentSession!.id,
      action: SessionAction.resumed,
      data: {
        'remainingSeconds': _remainingSeconds,
        'actualFocusMinutes': actualFocusMinutes,
      },
      note: 'Tiếp tục phiên tập trung',
    );
    
    _startTimer();
    notifyListeners();
  }

  // Resume session from storage
  Future<void> _resumeSession(FocusSession session) async {
    print('FocusService: Resuming session ${session.id} - status: ${session.status}');
    
    _currentSession = session;
    _isActive = session.isActive;
    
    if (_isActive) {
      if (session.status == SessionStatus.paused && session.remainingSeconds != null) {
        // Đang pause, khôi phục đúng trạng thái
        _remainingSeconds = session.remainingSeconds!;
        print('FocusService: Resumed paused session with ${_remainingSeconds}s remaining');
        // Không chạy timer, chỉ notify để UI hiển thị đúng
        notifyListeners();
      } else if (session.status == SessionStatus.running) {
        final now = DateTime.now();
        final expectedEndTime = session.startTime.add(Duration(minutes: session.durationMinutes));
        final remainingSeconds = expectedEndTime.difference(now).inSeconds;
        
        print('FocusService: Session expected end: $expectedEndTime, now: $now, remaining: ${remainingSeconds}s');
      
        if (remainingSeconds > 0) {
          _remainingSeconds = remainingSeconds;
          print('FocusService: Resuming running session with ${_remainingSeconds}s remaining');
          _startTimer();
        } else {
          // Session has expired - sử dụng silent để tránh tạo history entry
          print('FocusService: Session expired, completing silently');
          await stopSession(completed: true, silent: true);
        }
      }
    }
  }

  // Start timer
  void _startTimer() {
    print('FocusService: Bắt đầu _startTimer');
    
    // Đảm bảo không có timer cũ chạy song song
    _timer?.cancel();
    
    if (_currentSession == null || !_isActive) {
      print('FocusService: Không thể start timer - session null hoặc không active');
      return;
    }
    
    // Hiển thị thông báo liên tục ngay khi bắt đầu
    _updateProgressNotification();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      try {
        if (_remainingSeconds > 0 && _isActive && _currentSession != null) {
          _remainingSeconds--;
          
          // Update session với thời gian còn lại
          if (_currentSession != null) {
            _currentSession = _currentSession!.copyWith(
              remainingSeconds: _remainingSeconds,
              lastActivityTime: DateTime.now(),
            );
          }
          
          // Cập nhật thông báo liên tục mỗi 5 giây
          if (_remainingSeconds % 5 == 0) {
            _updateProgressNotification();
          }
          
          // Auto save timer state và session state mỗi 10 giây
          if (_remainingSeconds % 10 == 0) {
            autoSaveTimerState();
            autoSaveSessionState();
          }
          
          // Tính phần trăm hoàn thành chính xác
          final percentage = _currentSession!.calculateCompletionPercentage() * 100;
          
          // Thông báo động viên mỗi 25% (tùy chọn)
          if (_remainingSeconds % ((_currentSession!.durationSeconds * 0.25).round()) == 0 && 
              percentage > 0 && percentage < 100) {
            _notificationService.showMotivationalNotification(
              completionPercentage: percentage,
              remainingMinutes: _remainingSeconds ~/ 60,
            );
          }
          
          // Update UI
          notifyListeners();
          
          // Log progress mỗi phút
          if (_remainingSeconds % 60 == 0) {
            print('FocusService: Timer - ${_remainingSeconds ~/ 60} phút còn lại');
          }
        } else {
          print('FocusService: Timer kết thúc - remainingSeconds: $_remainingSeconds, isActive: $_isActive');
          timer.cancel();
          
          // Hủy thông báo liên tục
          _notificationService.cancelFocusProgressNotification();
          
          // Kiểm tra xem session có còn tồn tại không trước khi gọi stopSession
          if (_currentSession != null && _isActive) {
            print('FocusService: Gọi stopSession từ timer');
            stopSession(completed: true);
          }
        }
      } catch (e) {
        print('FocusService: Lỗi trong timer: $e');
        timer.cancel();
      }
    });
    
    print('FocusService: Timer đã được khởi tạo');
  }

  // Thêm method mới để cập nhật thông báo liên tục
  Future<void> _updateProgressNotification() async {
    if (_currentSession == null || !_isActive) return;
    
    final remainingMinutes = _remainingSeconds ~/ 60;
    final completionPercentage = _currentSession!.calculateCompletionPercentage() * 100;
    
    await _notificationService.showFocusProgressNotification(
      remainingMinutes: remainingMinutes,
      remainingSeconds: _remainingSeconds,
      completionPercentage: completionPercentage,
      goal: _currentSession!.goal,
    );
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
      
      // Restart app blocking with new list
      final appsToBlock = apps.where((app) => app.isBlocked).toList();
      await _appBlockingService.stopBlocking();
      await _appBlockingService.startBlocking(appsToBlock);
      print('FocusService: Restarted app blocking with ${appsToBlock.length} apps');
      
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

  // Fix sessions với dữ liệu không chính xác
  Future<void> fixIncorrectSessions() async {
    print('FocusService: Bắt đầu fix sessions không chính xác');
    
    bool hasFixed = false;
    for (int i = 0; i < _sessions.length; i++) {
      final session = _sessions[i];
      final calculatedActualTime = session.calculateActualFocusTime();
      
      // Kiểm tra nếu actualFocusMinutes không chính xác
      if (session.actualFocusMinutes != null && 
          session.actualFocusMinutes != calculatedActualTime &&
          (session.status == SessionStatus.completed || session.status == SessionStatus.cancelled)) {
        
        print('FocusService: Fix session ${session.id} - old: ${session.actualFocusMinutes}, new: $calculatedActualTime');
        
        final fixedSession = session.copyWith(
          actualFocusMinutes: calculatedActualTime,
        );
        
        _sessions[i] = fixedSession;
        await _storageService.updateFocusSession(fixedSession);
        hasFixed = true;
      }
    }
    
    if (hasFixed) {
      await _statisticsService.updateSessions(_sessions);
      notifyListeners();
      print('FocusService: Đã fix ${_sessions.length} sessions');
    } else {
      print('FocusService: Không có session nào cần fix');
    }
  }

  // Debug method để kiểm tra logic tính toán
  void debugTimeCalculation() {
    if (_currentSession == null) {
      print('FocusService: Không có session hiện tại để debug');
      return;
    }
    
    print('=== DEBUG TIME CALCULATION ===');
    print('Session ID: ${_currentSession!.id}');
    print('Start Time: ${_currentSession!.startTime}');
    print('End Time: ${_currentSession!.endTime}');
    print('Paused Time: ${_currentSession!.pausedTime}');
    print('Status: ${_currentSession!.status}');
    print('Duration Minutes: ${_currentSession!.durationMinutes}');
    print('Actual Focus Minutes: ${_currentSession!.actualFocusMinutes}');
    print('Total Pause Time Minutes: ${_currentSession!.totalPauseTimeMinutes}');
    print('Remaining Seconds: ${_currentSession!.remainingSeconds}');
    print('Pause History Count: ${_currentSession!.pauseHistory.length}');
    
    for (int i = 0; i < _currentSession!.pauseHistory.length; i++) {
      final pause = _currentSession!.pauseHistory[i];
      print('  Pause $i: ${pause.pauseTime} -> ${pause.resumeTime} (${pause.durationMinutes}m)');
    }
    
    final calculatedActualTime = _currentSession!.calculateActualFocusTime();
    print('Calculated Actual Focus Time: $calculatedActualTime minutes');
    print('Completion Percentage: ${_currentSession!.calculateCompletionPercentage() * 100}%');
    print('==============================');
  }

  // Check and restore connection state
  Future<void> checkAndRestoreConnection() async {
    print('FocusService: Kiểm tra và khôi phục connection state');
    
    try {
      // Kiểm tra xem có session đang active không
      final activeSession = _sessions.where((session) => session.isActive).firstOrNull;
      
      if (activeSession != null) {
        print('FocusService: Tìm thấy active session, khôi phục...');
        await _resumeSession(activeSession);
      } else {
        print('FocusService: Không có active session');
        // Đảm bảo state được reset
        _isActive = false;
        _currentSession = null;
        _remainingSeconds = 0;
        _timer?.cancel();
        _timer = null;
      }
      
      notifyListeners();
      print('FocusService: Connection state đã được khôi phục');
      
    } catch (e) {
      print('FocusService: Lỗi khi khôi phục connection: $e');
      // Reset state nếu có lỗi
      _isActive = false;
      _currentSession = null;
      _remainingSeconds = 0;
      _timer?.cancel();
      _timer = null;
      notifyListeners();
    }
  }

  // Debug connection state
  void debugConnectionState() {
    print('=== DEBUG CONNECTION STATE ===');
    print('isActive: $_isActive');
    print('currentSession: ${_currentSession?.id}');
    print('remainingSeconds: $_remainingSeconds');
    print('timer: ${_timer != null ? "active" : "null"}');
    print('sessions count: ${_sessions.length}');
    print('active sessions: ${_sessions.where((s) => s.isActive).length}');
    print('=============================');
  }

  // Auto save session state
  Future<void> autoSaveSessionState() async {
    if (_currentSession != null) {
      print('FocusService: Auto save session state - ${_currentSession!.id}, remaining: ${_currentSession!.remainingSeconds}s');
      try {
        // Cập nhật session với thời gian còn lại hiện tại
        final updatedSession = _currentSession!.copyWith(
          remainingSeconds: _remainingSeconds,
          lastActivityTime: DateTime.now(),
        );
        
        await _storageService.updateFocusSession(updatedSession);
        _currentSession = updatedSession;
        
        // Cập nhật trong danh sách sessions
        final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
        if (index != -1) {
          _sessions[index] = updatedSession;
        }
        
        print('FocusService: Session state đã được lưu');
      } catch (e) {
        print('FocusService: Lỗi khi auto save session: $e');
      }
    }
  }

  // Auto save timer state
  Future<void> autoSaveTimerState() async {
    if (_currentSession != null && _isActive) {
      print('FocusService: Auto save timer state - remainingSeconds: $_remainingSeconds');
      try {
        // Lưu timer state vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('timer_remaining_seconds', _remainingSeconds);
        await prefs.setString('timer_session_id', _currentSession!.id);
        await prefs.setBool('timer_is_active', _isActive);
        print('FocusService: Timer state đã được lưu');
      } catch (e) {
        print('FocusService: Lỗi khi auto save timer: $e');
      }
    }
  }

  // Restore timer state
  Future<void> _restoreTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('timer_session_id');
      final isActive = prefs.getBool('timer_is_active') ?? false;
      
      if (sessionId != null && isActive) {
        final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
        
        if (sessionIndex != -1) {
          final session = _sessions[sessionIndex];
          
          if (session.isActive) {
            print('FocusService: Restore timer state - session: $sessionId');
            _currentSession = session;
            _isActive = true;
            _remainingSeconds = prefs.getInt('timer_remaining_seconds') ?? session.durationSeconds;
            
            // Start timer nếu còn thời gian
            if (_remainingSeconds > 0) {
              _startTimer();
            } else {
              // Session đã kết thúc
              await stopSession(completed: true);
            }
          }
        }
      }
    } catch (e) {
      print('FocusService: Lỗi khi restore timer: $e');
    }
  }



  // Sync to Firebase
  Future<void> syncToFirebase() async {
    print('FocusService: Syncing to Firebase...');
    
    try {
      // Check if user is logged in
      final authService = AuthService();
      final isLoggedIn = authService.isLoggedIn;
      
      if (!isLoggedIn) {
        print('FocusService: User not logged in, cannot sync to Firebase');
        return;
      }
      
      // Get local sessions
      final localSessions = await _storageService.getFocusSessions();
      print('FocusService: Found ${localSessions.length} local sessions to sync');
      
      // Get local history
      final localHistory = await _storageService.getSessionHistory();
      print('FocusService: Found ${localHistory.length} local history entries to sync');
      
      // Sync to Firebase
      final firebaseService = FirebaseStorageService();
      await firebaseService.init();
      
      // Sync sessions
      for (final session in localSessions) {
        await firebaseService.saveFocusSession(session);
        print('FocusService: Synced session ${session.id}');
      }
      
      // Sync history
      for (final entry in localHistory) {
        await firebaseService.addSessionHistory(entry);
        print('FocusService: Synced history entry ${entry.id}');
      }
      
      print('FocusService: Sync to Firebase completed successfully!');
      print('FocusService: Synced ${localSessions.length} sessions and ${localHistory.length} history entries');
      
    } catch (e) {
      print('FocusService: Error syncing to Firebase: $e');
    }
  }



  // Clear user data when logging out
  Future<void> clearUserData() async {
    print('FocusService: Clearing user data...');
    
    // Stop current session if any
    if (_isActive || _currentSession != null) {
      await stopSession(silent: true);
    }
    
    // Clear local data
    await _storageService.clearAllData();
    
    // Reset service state
    _currentSession = null;
    _timer?.cancel();
    _timer = null;
    _remainingSeconds = 0;
    _isActive = false;
    _sessions = [];
    _blockedApps = [];
    _isStartingSession = false;
    _lastSessionId = null;
    _lastStartTime = null;
    
    print('FocusService: User data cleared successfully');
    notifyListeners();
  }

  // Load user-specific data when logging in
  Future<void> loadUserData() async {
    print('FocusService: Loading user-specific data...');
    
    try {
      // Load user-specific sessions
      _sessions = await _storageService.getFocusSessions();
      print('FocusService: Loaded ${_sessions.length} user-specific sessions');
      
      // Load user-specific blocked apps
      _blockedApps = await _storageService.getBlockedApps();
      print('FocusService: Loaded ${_blockedApps.length} user-specific blocked apps');
      
      // Check for active session
      final activeSession = _sessions.where((session) => session.isActive).firstOrNull;
      if (activeSession != null) {
        print('FocusService: Found active session for user, resuming...');
        await _resumeSession(activeSession);
      }
      
      // Update statistics
      await _statisticsService.updateSessions(_sessions);
      
      print('FocusService: User-specific data loaded successfully');
      notifyListeners();
      
    } catch (e) {
      print('FocusService: Error loading user data: $e');
    }
  }

  // Dispose
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}