import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:focuslock/services/notification_service.dart';
import 'package:focuslock/services/statistics_service.dart';
import 'package:focuslock/services/hybrid_storage_service.dart';
import 'package:focuslock/services/app_blocking_service.dart';
import 'package:focuslock/services/storage_service.dart';
import 'package:focuslock/services/firebase_storage_service.dart';
import 'package:focuslock/services/focus_service.dart';
import 'package:focuslock/services/auth_service.dart';
import 'package:focuslock/models/focus_session.dart';
import 'package:focuslock/models/session_status.dart';
import 'package:focuslock/models/session_history.dart';
import 'package:focuslock/models/app_info.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock classes
// Mock classes
class MockHybridStorageService extends Mock implements HybridStorageService {
  @override
  Future<void> init() => super.noSuchMethod(
    Invocation.method(#init, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  bool get isLoggedIn => super.noSuchMethod(
    Invocation.getter(#isLoggedIn),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  
  @override
  Future<void> saveFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#saveFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<FocusSession>> getFocusSessions() => super.noSuchMethod(
    Invocation.method(#getFocusSessions, []),
    returnValue: Future.value(<FocusSession>[]),
    returnValueForMissingStub: Future.value(<FocusSession>[]),
  );
  
  @override
  Future<void> addFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#addFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> updateFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#updateFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> removeFocusSession(String sessionId) => super.noSuchMethod(
    Invocation.method(#removeFocusSession, [sessionId]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> saveBlockedApps(List<AppInfo> apps) => super.noSuchMethod(
    Invocation.method(#saveBlockedApps, [apps]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<AppInfo>> getBlockedApps() => super.noSuchMethod(
    Invocation.method(#getBlockedApps, []),
    returnValue: Future.value(<AppInfo>[]),
    returnValueForMissingStub: Future.value(<AppInfo>[]),
  );
  
  @override
  Future<void> saveSessionHistory(List<SessionHistory> history) => super.noSuchMethod(
    Invocation.method(#saveSessionHistory, [history]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<SessionHistory>> getSessionHistory() => super.noSuchMethod(
    Invocation.method(#getSessionHistory, []),
    returnValue: Future.value(<SessionHistory>[]),
    returnValueForMissingStub: Future.value(<SessionHistory>[]),
  );
  
  @override
  Future<void> addSessionHistory(SessionHistory entry) => super.noSuchMethod(
    Invocation.method(#addSessionHistory, [entry]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> saveStatistics(SessionStatistics statistics) => super.noSuchMethod(
    Invocation.method(#saveStatistics, [statistics]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<SessionStatistics?> getStatistics() => super.noSuchMethod(
    Invocation.method(#getStatistics, []),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
  
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) => super.noSuchMethod(
    Invocation.method(#saveSettings, [settings]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<Map<String, dynamic>> getSettings() => super.noSuchMethod(
    Invocation.method(#getSettings, []),
    returnValue: Future.value(<String, dynamic>{}),
    returnValueForMissingStub: Future.value(<String, dynamic>{}),
  );
  
  @override
  Future<void> syncToFirebase() => super.noSuchMethod(
    Invocation.method(#syncToFirebase, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<Map<String, dynamic>> getStorageInfo() => super.noSuchMethod(
    Invocation.method(#getStorageInfo, []),
    returnValue: Future.value(<String, dynamic>{}),
    returnValueForMissingStub: Future.value(<String, dynamic>{}),
  );
}

class MockAppBlockingService extends Mock implements AppBlockingService {
  @override
  Future<void> init() => super.noSuchMethod(
    Invocation.method(#init, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
}

class MockStorageService extends Mock implements StorageService {
  @override
  Future<void> init() => super.noSuchMethod(
    Invocation.method(#init, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<FocusSession>> getFocusSessions() => super.noSuchMethod(
    Invocation.method(#getFocusSessions, []),
    returnValue: Future.value(<FocusSession>[]),
    returnValueForMissingStub: Future.value(<FocusSession>[]),
  );
  
  @override
  Future<void> saveFocusSessions(List<FocusSession> sessions) => super.noSuchMethod(
    Invocation.method(#saveFocusSessions, [sessions]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> addFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#addFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> updateFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#updateFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> removeFocusSession(String sessionId) => super.noSuchMethod(
    Invocation.method(#removeFocusSession, [sessionId]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<AppInfo>> getBlockedApps() => super.noSuchMethod(
    Invocation.method(#getBlockedApps, []),
    returnValue: Future.value(<AppInfo>[]),
    returnValueForMissingStub: Future.value(<AppInfo>[]),
  );
  
  @override
  Future<void> saveBlockedApps(List<AppInfo> apps) => super.noSuchMethod(
    Invocation.method(#saveBlockedApps, [apps]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<SessionHistory>> getSessionHistory() => super.noSuchMethod(
    Invocation.method(#getSessionHistory, []),
    returnValue: Future.value(<SessionHistory>[]),
    returnValueForMissingStub: Future.value(<SessionHistory>[]),
  );
  
  @override
  Future<void> saveSessionHistory(List<SessionHistory> history) => super.noSuchMethod(
    Invocation.method(#saveSessionHistory, [history]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> addSessionHistory(SessionHistory entry) => super.noSuchMethod(
    Invocation.method(#addSessionHistory, [entry]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> saveStatistics(SessionStatistics statistics) => super.noSuchMethod(
    Invocation.method(#saveStatistics, [statistics]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<SessionStatistics?> getStatistics() => super.noSuchMethod(
    Invocation.method(#getStatistics, []),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
  
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) => super.noSuchMethod(
    Invocation.method(#saveSettings, [settings]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<Map<String, dynamic>> getSettings() => super.noSuchMethod(
    Invocation.method(#getSettings, []),
    returnValue: Future.value(<String, dynamic>{}),
    returnValueForMissingStub: Future.value(<String, dynamic>{}),
  );
}

class MockFirebaseStorageService extends Mock implements FirebaseStorageService {
  @override
  Future<void> init() => super.noSuchMethod(
    Invocation.method(#init, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  bool get isLoggedIn => super.noSuchMethod(
    Invocation.getter(#isLoggedIn),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  
  @override
  Future<List<FocusSession>> getFocusSessions() => super.noSuchMethod(
    Invocation.method(#getFocusSessions, []),
    returnValue: Future.value(<FocusSession>[]),
    returnValueForMissingStub: Future.value(<FocusSession>[]),
  );
  
  @override
  Future<void> saveFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#saveFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> updateFocusSession(FocusSession session) => super.noSuchMethod(
    Invocation.method(#updateFocusSession, [session]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> removeFocusSession(String sessionId) => super.noSuchMethod(
    Invocation.method(#removeFocusSession, [sessionId]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<AppInfo>> getBlockedApps() => super.noSuchMethod(
    Invocation.method(#getBlockedApps, []),
    returnValue: Future.value(<AppInfo>[]),
    returnValueForMissingStub: Future.value(<AppInfo>[]),
  );
  
  @override
  Future<void> saveBlockedApps(List<AppInfo> apps) => super.noSuchMethod(
    Invocation.method(#saveBlockedApps, [apps]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<List<SessionHistory>> getSessionHistory() => super.noSuchMethod(
    Invocation.method(#getSessionHistory, []),
    returnValue: Future.value(<SessionHistory>[]),
    returnValueForMissingStub: Future.value(<SessionHistory>[]),
  );
  
  @override
  Future<void> saveSessionHistory(List<SessionHistory> history) => super.noSuchMethod(
    Invocation.method(#saveSessionHistory, [history]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> addSessionHistory(SessionHistory entry) => super.noSuchMethod(
    Invocation.method(#addSessionHistory, [entry]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> saveStatistics(SessionStatistics statistics) => super.noSuchMethod(
    Invocation.method(#saveStatistics, [statistics]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<SessionStatistics?> getStatistics() => super.noSuchMethod(
    Invocation.method(#getStatistics, []),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
  
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) => super.noSuchMethod(
    Invocation.method(#saveSettings, [settings]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<Map<String, dynamic>> getSettings() => super.noSuchMethod(
    Invocation.method(#getSettings, []),
    returnValue: Future.value(<String, dynamic>{}),
    returnValueForMissingStub: Future.value(<String, dynamic>{}),
  );
  
  @override
  Future<void> syncFromLocal(List<FocusSession> sessions, List<SessionHistory> history) => super.noSuchMethod(
    Invocation.method(#syncFromLocal, [sessions, history]),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
}
class MockFocusService extends Mock implements FocusService {
  @override
  List<FocusSession> get sessions => super.noSuchMethod(
    Invocation.getter(#sessions),
    returnValue: <FocusSession>[],
    returnValueForMissingStub: <FocusSession>[],
  );
  
  @override
  bool get isActive => super.noSuchMethod(
    Invocation.getter(#isActive),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  
  @override
  FocusSession? get currentSession => super.noSuchMethod(
    Invocation.getter(#currentSession),
    returnValue: null,
    returnValueForMissingStub: null,
  );
  
  @override
  int get remainingSeconds => super.noSuchMethod(
    Invocation.getter(#remainingSeconds),
    returnValue: 0,
    returnValueForMissingStub: 0,
  );
  
  @override
  List<AppInfo> get blockedApps => super.noSuchMethod(
    Invocation.getter(#blockedApps),
    returnValue: <AppInfo>[],
    returnValueForMissingStub: <AppInfo>[],
  );
  
  @override
  bool get hasSelectedApps => super.noSuchMethod(
    Invocation.getter(#hasSelectedApps),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  
  @override
  List<AppInfo> get selectedApps => super.noSuchMethod(
    Invocation.getter(#selectedApps),
    returnValue: <AppInfo>[],
    returnValueForMissingStub: <AppInfo>[],
  );
  
  // Added missing getCompletionPercentage method
  @override
  double getCompletionPercentage() => super.noSuchMethod(
    Invocation.method(#getCompletionPercentage, []),
    returnValue: 0.0,
    returnValueForMissingStub: 0.0,
  );
  
  // Add startSession method override
  @override
  Future<void> startSession({required int durationMinutes, String? goal}) => super.noSuchMethod(
    Invocation.method(#startSession, [], {#durationMinutes: durationMinutes, #goal: goal}),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  // Add other missing async methods
  @override
  Future<void> pauseSession() => super.noSuchMethod(
    Invocation.method(#pauseSession, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> resumeSession() => super.noSuchMethod(
    Invocation.method(#resumeSession, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  @override
  Future<void> stopSession({bool completed = false, bool silent = false}) => super.noSuchMethod(
    Invocation.method(#stopSession, [], {#completed: completed, #silent: silent}),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  // Thêm method clearUserData bị thiếu
  @override
  Future<void> clearUserData() => super.noSuchMethod(
    Invocation.method(#clearUserData, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
  
  // Thêm method loadUserData nếu cần
  @override
  Future<void> loadUserData() => super.noSuchMethod(
    Invocation.method(#loadUserData, []),
    returnValue: Future<void>.value(),
    returnValueForMissingStub: Future<void>.value(),
  );
}

class MockAuthService extends Mock implements AuthService {
  @override
  bool get isLoggedIn => super.noSuchMethod(
    Invocation.getter(#isLoggedIn),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  
  @override
  User? get currentUser => super.noSuchMethod(
    Invocation.getter(#currentUser),
    returnValue: null,
    returnValueForMissingStub: null,
  );
  
  // Thêm phương thức này để sửa lỗi
  @override
  Stream<User?> authStateChanges() => super.noSuchMethod(
    Invocation.method(#authStateChanges, []),
    returnValue: Stream<User?>.value(null),
    returnValueForMissingStub: Stream<User?>.value(null),
  );
}

class MockUser extends Mock implements User {
  final String _uid;
  final String? _email;
  final String? _displayName;
  final bool _emailVerified;
  
  MockUser({
    required String uid,
    String? email,
    String? displayName,
    bool emailVerified = false,
  }) : _uid = uid,
       _email = email,
       _displayName = displayName,
       _emailVerified = emailVerified;
       
  @override
  String get uid => _uid;
  
  @override
  String? get email => _email;
  
  @override
  String? get displayName => _displayName;
  
  @override
  bool get emailVerified => _emailVerified;
  
  @override
  bool get isAnonymous => false;
  
  @override
  UserMetadata get metadata => throw UnimplementedError();
  
  @override
  List<UserInfo> get providerData => [];
  
  @override
  String? get refreshToken => null;
  
  @override
  String? get tenantId => null;
  
  @override
  String? get phoneNumber => null;
  
  @override
  String? get photoURL => null;
  
  @override
  Future<void> delete() => throw UnimplementedError();
  
  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();
  
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();
  
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();
  
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();
  
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
  
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();
  
  @override
  Future<void> reload() => throw UnimplementedError();
  
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  
  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();
  
  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();
  
  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();
  
  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();
  
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();
  
  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();
  
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}

// Mock notification service
class MockNotificationService extends Mock implements NotificationService {}

// Extended Mock notification service with additional test functionality
class ExtendedMockNotificationService extends MockNotificationService {
  int _lastNotificationId = 0;
  
  int get lastNotificationId => _lastNotificationId;
  
  @override
  Future<void> showFocusStartNotification({
    required int durationMinutes,
    String? goal, // Fixed: Changed from required String to String?
  }) async {
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch;
    return super.noSuchMethod(
      Invocation.method(#showFocusStartNotification, [], {
        #durationMinutes: durationMinutes,
        #goal: goal,
      }),
      returnValue: Future<void>.value(),
    );
  }
  
  @override
  Future<void> showFocusEndNotification({ // Fixed: Changed from showFocusCompleteNotification
    required int durationMinutes,
    required bool completed,
    String? goal,
  }) async {
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch;
    return super.noSuchMethod(
      Invocation.method(#showFocusEndNotification, [], {
        #durationMinutes: durationMinutes,
        #completed: completed,
        #goal: goal,
      }),
      returnValue: Future<void>.value(),
    );
  }
  
  // Added missing methods that tests expect
  Future<void> showFocusPausedNotification() async {
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch;
    return super.noSuchMethod(
      Invocation.method(#showFocusPausedNotification, []),
      returnValue: Future<void>.value(),
    );
  }
  
  Future<void> showFocusResumedNotification() async {
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch;
    return super.noSuchMethod(
      Invocation.method(#showFocusResumedNotification, []),
      returnValue: Future<void>.value(),
    );
  }
  
  @override
  Future<void> showFocusProgressNotification({
    required int remainingMinutes,
    required int remainingSeconds,
    required double completionPercentage,
    String? goal,
  }) async {
    _lastNotificationId = DateTime.now().millisecondsSinceEpoch;
    return super.noSuchMethod(
      Invocation.method(#showFocusProgressNotification, [], {
        #remainingMinutes: remainingMinutes,
        #remainingSeconds: remainingSeconds,
        #completionPercentage: completionPercentage,
        #goal: goal,
      }),
      returnValue: Future<void>.value(),
    );
  }
  
  @override
  Future<void> cancelNotification(int id) async {
    return super.noSuchMethod(
      Invocation.method(#cancelNotification, [id]),
      returnValue: Future<void>.value(),
    );
  }
}

// Mock statistics service  
class MockStatisticsService extends Mock implements StatisticsService {}

// Extended Mock statistics service with additional test functionality
class ExtendedMockStatisticsService extends MockStatisticsService {
  Map<String, dynamic> _mockStatistics = {};
  
  void setMockStatistics(Map<String, dynamic> stats) {
    _mockStatistics = stats;
  }
  
  @override
  Future<Map<String, dynamic>> calculateSessionStatistics(List<FocusSession> sessions) async {
    if (_mockStatistics.isNotEmpty) {
      return _mockStatistics;
    }
    
    return super.noSuchMethod(
      Invocation.method(#calculateSessionStatistics, [sessions]),
      returnValue: Future.value(<String, dynamic>{}),
    );
  }
  
  @override
  Future<void> updateSessionStatistics(FocusSession session) async {
    return super.noSuchMethod(
      Invocation.method(#updateSessionStatistics, [session]),
      returnValue: Future<void>.value(),
    );
  }
}