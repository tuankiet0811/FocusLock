import 'package:flutter/material.dart';
import 'debug_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onRestart;
  const SettingsScreen({Key? key, this.onRestart}) : super(key: key);

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
        backgroundColor: const Color(0xFF2196F3),
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
                      backgroundColor: const Color(0xFF2196F3),
                      child: Text(
                        _getInitials(user?.displayName, user?.email),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user?.displayName ?? 'Chưa đặt tên'),
                    subtitle: Text(user?.email ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProfileScreen(onRestart: onRestart)),
                      );
                    },
                  );
                },
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
                leading: const Icon(Icons.notifications),
                title: const Text('Thông báo'),
                subtitle: const Text('Cài đặt thông báo'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to notification settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Quyền truy cập'),
                subtitle: const Text('Cài đặt quyền ứng dụng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to permission settings
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Developer Section
          _buildSection(
            title: 'Nhà phát triển',
            icon: Icons.developer_mode,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Debug'),
                subtitle: const Text('Thông tin debug và logs'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DebugScreen()),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSection(
            title: 'Thông tin',
            icon: Icons.info,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Điều khoản sử dụng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to terms of service
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Trợ giúp'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to help
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Version Info
          Center(
            child: Text(
              'FocusLock v1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
                Icon(icon, color: const Color(0xFF2196F3)),
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
} 