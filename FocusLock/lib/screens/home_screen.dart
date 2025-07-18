import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../widgets/focus_timer_widget.dart';
import '../widgets/quick_start_widget.dart';
import '../widgets/stats_widget.dart';
import 'apps_screen.dart';
import 'debug_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_blocking_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _checkAndShowPermissionDialog();
  }

  Future<void> _checkAndShowPermissionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shown_permission_dialog') ?? false;
    if (!shown) {
      Future.delayed(Duration.zero, () => _showPermissionDialog());
      await prefs.setBool('shown_permission_dialog', true);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cấp quyền cho FocusLock'),
        content: const Text(
          'Để FocusLock hoạt động hiệu quả, bạn cần bật Accessibility Service.\n\n'
          'Accessibility Service giúp ứng dụng chặn các app khác một cách hiệu quả hơn.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return; // Thêm kiểm tra mounted
              Navigator.of(context).pop();
            },
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return; // Thêm kiểm tra mounted
              _openAccessibilitySettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('⛿ Bật Accessibility Service'),
          ),
        ],
      ),
    );
  }

  void _openAccessibilitySettings() {
    if (!mounted) return; // Thêm kiểm tra mounted
    final intent = AndroidIntent(
      action: 'android.settings.ACCESSIBILITY_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
    
    if (!mounted) return; // Kiểm tra lại trước khi show SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã mở cài đặt Accessibility. Tìm FocusLock và bật dịch vụ'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(AppConstants.primaryColor),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Ứng dụng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: 'Debug',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(FocusService focusService) {
    final recentSessions = focusService.sessions
        .where((session) => !session.isActive)
        .take(5)
        .toList();

    if (recentSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có phiên tập trung nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu phiên tập trung đầu tiên của bạn!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: Color(AppConstants.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Phiên gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to history screen
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSessions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = recentSessions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  child: Icon(
                    Icons.timer,
                    color: const Color(AppConstants.primaryColor),
                  ),
                ),
                title: Text(
                  session.goal ?? 'Phiên tập trung',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${Helpers.formatDuration(session.durationMinutes)} • ${Helpers.formatDate(session.startTime)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  Helpers.formatDuration(session.durationMinutes),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildHistoryContent();
      case 2:
        return const AppsScreen();
      case 3:
        return const DebugScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        return SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(AppConstants.primaryColor),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'FocusLock',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(AppConstants.primaryColor),
                              Color(0xFF1976D2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          // TODO: Navigate to settings
                        },
                      ),
                      Consumer<AuthService>(
                        builder: (context, authService, _) {
                          final isLoggedIn = authService.currentUser != null;
                          return Row(
                            children: [
                              if (isLoggedIn)
                                IconButton(
                                  icon: const Icon(Icons.account_circle, color: Colors.white),
                                  tooltip: 'Thông tin tài khoản',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                    );
                                  },
                                ),
                              isLoggedIn
                                  ? IconButton(
                                      icon: const Icon(Icons.logout, color: Colors.white),
                                      tooltip: 'Đăng xuất',
                                      onPressed: () async {
                                        await authService.signOut();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã đăng xuất thành công!')),
                                          );
                                        }
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.login, color: Colors.white),
                                      tooltip: 'Đăng nhập',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        );
                                      },
                                    ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Message
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: Color(AppConstants.primaryColor),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      focusService.isActive 
                                          ? 'Đang tập trung...' 
                                          : 'Sẵn sàng tập trung?',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      focusService.isActive
                                          ? 'Hãy giữ vững tinh thần!'
                                          : 'Hãy bắt đầu phiên tập trung mới',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Focus Timer Widget
                        if (focusService.currentSession != null &&
                            (focusService.isActive || focusService.currentSession?.pausedTime != null)) ...[
                          FocusTimerWidget(
                            key: ValueKey('${focusService.currentSession?.id}_${focusService.currentSession?.pausedTime}'),
                            remainingSeconds: focusService.remainingSeconds,
                            completionPercentage: focusService.getCompletionPercentage() * 100,
                            onStop: () => focusService.stopSession(),
                            onPauseOrResume: () async {
                              if (focusService.currentSession?.pausedTime != null) {
                                await focusService.resumeSession();
                              } else {
                                await focusService.pauseSession();
                              }
                              setState(() {});
                            },
                            isPaused: focusService.currentSession?.pausedTime != null,
                          ),
                          const SizedBox(height: 24),
                        ],


                        // Quick Start Widget
                        if (!focusService.isActive && focusService.currentSession?.pausedTime == null) ...[
                          QuickStartWidget(
                            onStartSession: (duration, goal) {
                              focusService.startSession(
                                durationMinutes: duration,
                                goal: goal,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Statistics Widget
                        StatsWidget(
                          todayFocusTime: focusService.getTodayFocusTime(),
                          thisWeekFocusTime: focusService.getThisWeekFocusTime(),
                          totalSessions: focusService.sessions.length,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Recent Sessions
                        _buildRecentSessions(focusService),
                        
                        const SizedBox(height: 100), // Bottom padding
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent() {
    return const Center(
      child: Text('Lịch sử - Coming Soon'),
    );
  }

  Widget _buildStatsContent() {
    return const Center(
      child: Text('Thống kê - Coming Soon'),
    );
  }
} 