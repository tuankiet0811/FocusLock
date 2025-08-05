import 'package:flutter/material.dart';
import 'debug_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // Thêm import này
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const SettingsScreen({Key? key, this.onRestart}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _theme = 'system';

  // Thêm instance của NotificationService
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkSystemNotificationSettings(); // Thêm dòng này
  }

  // Thêm method kiểm tra cài đặt hệ thống
  Future<void> _checkSystemNotificationSettings() async {
    final notificationService = NotificationService();
    await notificationService.syncWithSystemSettings(
      showUserNotification: true,
    );

    // Reload settings để cập nhật UI
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _theme = prefs.getString('theme') ?? 'system';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Cập nhật cài đặt thông báo khi có thay đổi
    if (key.contains('notification') ||
        key.contains('sound') ||
        key.contains('vibration')) {
      await _notificationService.updateNotificationSettings();
    }
  }

  String _getInitials(String? displayName, String? email) {
    String text = displayName ?? email ?? 'U';
    if (text.isEmpty) return 'U';
    return text.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSection(
            title: 'Tài khoản',
            icon: Icons.account_circle,
            children: [
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  final user = authService.currentUser;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(AppConstants.primaryColor),
                      child: Text(
                        _getInitials(user?.displayName, user?.email),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user?.displayName ?? 'Chưa đặt tên'),
                    subtitle: Text(user?.email ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(onRestart: widget.onRestart),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notification Settings Section
          _buildSection(
            title: 'Thông báo',
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('Bật thông báo'),
                subtitle: const Text('Nhận thông báo về phiên tập trung'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSetting('notifications_enabled', value);

                  // Hiển thị thông báo xác nhận
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Đã bật thông báo' : 'Đã tắt thông báo',
                      ),
                      backgroundColor: value ? Colors.green : Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('Âm thanh'),
                subtitle: const Text('Phát âm thanh khi có thông báo'),
                value: _soundEnabled,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                        _saveSetting('sound_enabled', value);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Đã bật âm thanh thông báo'
                                  : 'Đã tắt âm thanh thông báo',
                            ),
                            backgroundColor: value
                                ? Colors.green
                                : Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Rung'),
                subtitle: const Text('Rung khi có thông báo'),
                value: _vibrationEnabled,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _vibrationEnabled = value;
                        });
                        _saveSetting('vibration_enabled', value);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Đã bật rung thông báo'
                                  : 'Đã tắt rung thông báo',
                            ),
                            backgroundColor: value
                                ? Colors.green
                                : Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSection(
            title: 'Cài đặt ứng dụng',
            icon: Icons.settings,
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Quyền truy cập'),
                subtitle: const Text('Cài đặt quyền ứng dụng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DebugScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('Kiểm tra cập nhật'),
                subtitle: const Text(
                  'Phiên bản hiện tại: ${AppConstants.appVersion}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _checkForUpdates(),
              ),
            ],
          ),

          
          const SizedBox(height: 32),

          // Version Info
          Center(
            child: Column(
              children: [
                Text(
                  'FocusLock v${AppConstants.appVersion}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phát triển bởi FocusLock Team',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(AppConstants.primaryColor)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn chế độ hiển thị'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Theo hệ thống'),
              value: 'system',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                _saveSetting('theme', value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Sáng'),
              value: 'light',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                _saveSetting('theme', value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Tối'),
              value: 'dark',
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                _saveSetting('theme', value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      case 'system':
      default:
        return 'Theo hệ thống';
    }
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bạn đang sử dụng phiên bản mới nhất'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cảm ơn bạn đã sử dụng FocusLock!')),
    );
    // TODO: Open app store for rating
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chia sẻ FocusLock với bạn bè!')),
    );
    // TODO: Implement app sharing
  }
}
