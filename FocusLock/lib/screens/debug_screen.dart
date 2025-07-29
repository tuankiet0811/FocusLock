import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../services/app_blocking_service.dart';
import '../utils/constants.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final AppBlockingService _appBlockingService = AppBlockingService();
  static const platform = MethodChannel('focuslock/app_blocking');
  
  // State variables
  String _currentApp = 'Unknown';
  bool _isBlockingActive = false;
  List<String> _blockedApps = [];
  String? _overlayMessage;
  bool _hasPermissions = false;

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

    // Get current app and permissions
    try {
      final currentApp = await _appBlockingService.getCurrentApp();
      final hasPermissions = await _appBlockingService.checkPermissions();
      setState(() {
        _currentApp = currentApp ?? 'Unknown';
        _hasPermissions = hasPermissions;
      });
    } catch (e) {
      print('Error loading debug info: $e');
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      final bool result = await platform.invokeMethod('requestPermissions');
      setState(() {
        _overlayMessage = result
            ? 'Đã mở trang cấp quyền hiển thị trên ứng dụng khác.'
            : 'Không thể mở trang cấp quyền. Vui lòng kiểm tra cài đặt.';
      });
      // Refresh permissions after request
      await Future.delayed(const Duration(seconds: 1));
      _loadDebugInfo();
    } catch (e) {
      setState(() {
        _overlayMessage = 'Lỗi khi xin quyền overlay: \n${e.toString()}';
      });
    }
  }

  Future<void> _requestUsageAccessPermission() async {
    try {
      await platform.invokeMethod('requestUsageAccessPermission');
      // Refresh permissions after request
      await Future.delayed(const Duration(seconds: 1));
      _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xin quyền Usage Access: $e')),
      );
    }
  }

  Future<void> _openAccessibilitySettings() async {
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
  }

  Future<void> _debugCurrentApp() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Quyền truy cập'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PERMISSIONS STATUS SECTION
              _buildPermissionsStatusCard(),
              const SizedBox(height: 16),
              
              // 2. SYSTEM STATUS SECTION
              _buildSystemStatusCard(),
              const SizedBox(height: 16),
              
              // 3. BLOCKED APPS SECTION
              _buildBlockedAppsCard(),
              const SizedBox(height: 16),
              
              // 4. PERMISSION ACTIONS SECTION
              _buildPermissionActionsCard(),
              const SizedBox(height: 16),
              
              // 5. DEBUG ACTIONS SECTION
              _buildDebugActionsCard(),
              const SizedBox(height: 16),
              
              // 6. SETUP GUIDE SECTION
              _buildSetupGuideCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hasPermissions ? Icons.check_circle : Icons.error,
                  color: _hasPermissions ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trạng thái quyền',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasPermissions ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasPermissions ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasPermissions ? Icons.verified : Icons.warning,
                    color: _hasPermissions ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasPermissions 
                          ? 'Tất cả quyền đã được cấp - Ứng dụng hoạt động bình thường'
                          : 'Thiếu quyền cần thiết - Vui lòng cấp quyền bên dưới',
                      style: TextStyle(
                        color: _hasPermissions ? Colors.green.shade700 : Colors.red.shade700,
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
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái hệ thống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Chế độ Focus', _isBlockingActive ? 'Đang hoạt động' : 'Không hoạt động', _isBlockingActive),
            const SizedBox(height: 8),
            _buildStatusRow('Ứng dụng hiện tại', _currentApp, true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Row(
      children: [
        Icon(
          isGood ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isGood ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isGood ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedAppsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Ứng dụng bị chặn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_blockedApps.length}'),
                  backgroundColor: Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_blockedApps.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Chưa có ứng dụng nào được chọn để chặn'),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _blockedApps.map((app) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(app)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấp quyền cần thiết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Accessibility Service - Most important
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openAccessibilitySettings,
                icon: const Icon(Icons.accessibility),
                label: const Text('Bật Accessibility Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Overlay Permission
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestOverlayPermission,
                icon: const Icon(Icons.layers),
                label: const Text('Cấp quyền hiển thị trên ứng dụng khác'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Usage Access Permission
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestUsageAccessPermission,
                icon: const Icon(Icons.analytics),
                label: const Text('Cấp quyền truy cập sử dụng ứng dụng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            if (_overlayMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _overlayMessage!,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Công cụ debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadDebugInfo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _debugCurrentApp,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupGuideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: const Color(AppConstants.primaryColor),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hướng dẫn thiết lập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildGuideStep('1', 'Bật Accessibility Service', 
                'Nhấn nút "Bật Accessibility Service" ở trên, tìm FocusLock và bật toggle'),
            const SizedBox(height: 12),
            
            _buildGuideStep('2', 'Cấp quyền hiển thị', 
                'Nhấn "Cấp quyền hiển thị trên ứng dụng khác" và cho phép'),
            const SizedBox(height: 12),
            
            _buildGuideStep('3', 'Cấp quyền sử dụng', 
                'Nhấn "Cấp quyền truy cập sử dụng ứng dụng" và cho phép'),
            const SizedBox(height: 12),
            
            _buildGuideStep('4', 'Kiểm tra', 
                'Quay lại app chính và test chức năng chặn ứng dụng'),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sau khi hoàn thành các bước trên, ứng dụng sẽ hoạt động tối ưu',
                      style: TextStyle(
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
    );
  }

  Widget _buildGuideStep(String stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}