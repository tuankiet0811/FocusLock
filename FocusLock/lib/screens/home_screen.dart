import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../services/auth_service.dart';
import '../models/focus_session.dart';
import '../models/session_status.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'apps_screen.dart';
import '../widgets/focus_timer_widget.dart';
import '../widgets/quick_start_widget.dart';
import '../utils/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/hybrid_storage_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const HomeScreen({super.key, this.onRestart});

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
    _checkAndShowFirstTimeDialog();
  }

  Future<void> _checkAndShowPermissionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shown_permission_dialog') ?? false;
    if (!shown) {
      Future.delayed(Duration.zero, () => _showPermissionDialog());
      await prefs.setBool('shown_permission_dialog', true);
    }
  }

  Future<void> _checkAndShowFirstTimeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shown_first_time_dialog') ?? false;
    if (!shown) {
      Future.delayed(const Duration(seconds: 2), () => _showFirstTimeDialog());
      await prefs.setBool('shown_first_time_dialog', true);
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

  void _showFirstTimeDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, color: Color(AppConstants.primaryColor)),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Chào mừng đến với FocusLock!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Để bắt đầu sử dụng FocusLock hiệu quả:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('1. 📱 Vào tab "Ứng dụng" để chọn các app muốn chặn'),
            const SizedBox(height: 8),
            const Text('2. ⏱️ Quay lại tab "Trang chủ" để bắt đầu phiên tập trung'),
            const SizedBox(height: 8),
            const Text('3. 🎯 Đặt mục tiêu và thời gian tập trung'),
            const SizedBox(height: 8),
            const Text('4. 🚫 FocusLock sẽ chặn các app đã chọn trong thời gian tập trung'),
            const SizedBox(height: 12),
            const Text(
              '💡 Mẹo: Bạn có thể thay đổi danh sách app bị chặn bất cứ lúc nào!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).pop();
                // Chuyển đến tab Ứng dụng
                setState(() {
                  _currentIndex = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
              ),
              child: const Text('📱 Chọn ứng dụng ngay'),
            ),
          ),
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Để sau'),
          ),
        ],
        ),
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
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Ứng dụng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
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
        return const StatisticsScreen();
      case 2:
        return const AppsScreen();
      case 3:
        return ProfileScreen(onRestart: widget.onRestart);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        if (focusService.sessions == null) {
          return const Center(child: CircularProgressIndicator());
        }
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
                      Consumer<AuthService>(
                        builder: (context, authService, _) {
                          final isLoggedIn = authService.currentUser != null;
                          return Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.white),
                                tooltip: 'Cài đặt',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SettingsScreen(onRestart: widget.onRestart)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.bug_report, color: Colors.white),
                                tooltip: 'Debug',
                                onPressed: () {
                                  focusService.debugTimeCalculation();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã in debug info vào console'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                              if (isLoggedIn)
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  tooltip: 'Đăng xuất',
                                  onPressed: () async {
                                    try {
                                      print('HomeScreen: Bắt đầu đăng xuất từ app bar...');
                                      authService.debugAuthState(); // Debug trước khi đăng xuất
                                      await authService.signOut();
                                      print('HomeScreen: Đăng xuất thành công');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã đăng xuất thành công!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      print('HomeScreen: Lỗi khi đăng xuất: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                )
                              else
                                IconButton(
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
                            focusService.currentSession?.status != SessionStatus.completed &&
                            focusService.currentSession?.status != SessionStatus.cancelled) ...[
                          FocusTimerWidget(
                            key: ValueKey('${focusService.currentSession?.id}_${focusService.currentSession?.pausedTime}'),
                            remainingSeconds: focusService.remainingSeconds,
                            completionPercentage: focusService.getCompletionPercentage() * 100,
                            onStop: () => focusService.stopSession(),
                            onPauseOrResume: () async {
                              if (focusService.currentSession?.status == SessionStatus.paused) {
                                await focusService.resumeSession();
                              } else {
                                await focusService.pauseSession();
                              }
                              setState(() {});
                            },
                            isPaused: focusService.currentSession?.status == SessionStatus.paused,
                            pausedTime: focusService.currentSession?.pausedTime,
                            goal: focusService.currentSession?.goal,
                          ),
                          const SizedBox(height: 24),
                        ],


                        // Quick Start Widget
                        if (focusService.currentSession == null ||
                            (focusService.currentSession?.status == SessionStatus.completed ||
                             focusService.currentSession?.status == SessionStatus.cancelled)) ...[
                          QuickStartWidget(
                            hasSelectedApps: focusService.hasSelectedApps,
                            onStartSession: (duration, goal) async {
                              // Kiểm tra xem có ứng dụng nào được chọn không
                              if (!focusService.hasSelectedApps) {
                                // Hiển thị dialog xác nhận
                                final shouldContinue = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800)),
                                        SizedBox(width: 8),
                                        Text('Chưa chọn ứng dụng'),
                                      ],
                                    ),
                                    content: const Text(
                                      'Bạn chưa chọn ứng dụng nào để chặn. Phiên tập trung sẽ bắt đầu mà không chặn ứng dụng nào.\n\n'
                                      'Bạn có muốn tiếp tục không?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Hủy'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(AppConstants.primaryColor),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Tiếp tục'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldContinue != true) {
                                  return; // Người dùng hủy
                                }
                              }
                              
                              await focusService.startSession(
                                durationMinutes: duration,
                                goal: goal,
                              );
                              
                              // Hiển thị thông báo thành công
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      focusService.hasSelectedApps
                                          ? 'Đã bắt đầu phiên tập trung với ${focusService.selectedApps.length} ứng dụng bị chặn!'
                                          : 'Đã bắt đầu phiên tập trung!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                        
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


} 