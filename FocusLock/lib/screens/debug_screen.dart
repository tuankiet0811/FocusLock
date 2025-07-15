import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../services/app_blocking_service.dart';
import '../utils/constants.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final AppBlockingService _appBlockingService = AppBlockingService();
  String _currentApp = 'Unknown';
  bool _isBlockingActive = false;
  List<String> _blockedApps = [];

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final focusService = Provider.of<FocusService>(context, listen: false);
    
    setState(() {
      _isBlockingActive = focusService.isActive;
      _blockedApps = focusService.blockedApps
          .where((app) => app.isBlocked)
          .map((app) => '${app.appName} (${app.packageName})')
          .toList();
    });

    // Get current app
    try {
      final currentApp = await _appBlockingService.getCurrentApp();
      setState(() {
        _currentApp = currentApp ?? 'Unknown';
      });
    } catch (e) {
      print('Error getting current app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái Focus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Đang hoạt động: ${_isBlockingActive ? "Có" : "Không"}'),
                      const SizedBox(height: 8),
                      Text('Ứng dụng hiện tại: $_currentApp'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ứng dụng bị chặn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_blockedApps.isEmpty)
                        const Text('Không có ứng dụng nào được chọn')
                      else
                        ..._blockedApps.map((app) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $app'),
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thao tác',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDebugInfo,
                        child: const Text('Làm mới thông tin'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final hasPermissions = await _appBlockingService.checkPermissions();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Permissions: ${hasPermissions ? "Granted" : "Not granted"}'),
                            ),
                          );
                        },
                        child: const Text('Kiểm tra quyền'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final debugInfo = await _appBlockingService.debugCurrentApp();
                          final currentApp = debugInfo['currentApp'] ?? 'Unknown';
                          final isBlocking = debugInfo['isBlockingActive'] ?? false;
                          final blockedApps = List<String>.from(debugInfo['blockedApps'] ?? []);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('App hiện tại: $currentApp\nChặn: $isBlocking\nĐã chặn: ${blockedApps.join(", ")}'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        },
                        child: const Text('Debug App Hiện Tại'),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final intent = AndroidIntent(
                              action: 'android.settings.ACCESSIBILITY_SETTINGS',
                              flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                            );
                            intent.launch();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã mở cài đặt Accessibility. Tìm FocusLock và bật dịch vụ'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.primaryColor),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '♿ Bật Accessibility Service',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(AppConstants.primaryColor).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(AppConstants.primaryColor),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'HƯỚNG DẪN CẤP QUYỀN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppConstants.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '1. Nhấn nút "Bật Accessibility Service" ở trên\n'
                              '2. Tìm FocusLock trong danh sách dịch vụ trợ năng\n'
                              '3. Bật toggle cho FocusLock\n'
                              '4. Quay lại app và test chặn app',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '✅ Accessibility Service giúp chặn app hiệu quả hơn\n'
                                '✅ Hoạt động trên mọi thiết bị Android',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 