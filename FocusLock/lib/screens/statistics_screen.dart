import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/focus_service.dart';
import '../services/app_usage_service.dart';
import '../services/app_blocking_service.dart';
import '../models/focus_session.dart';
import '../models/session_status.dart';
import '../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'today';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Thống kê chi tiết'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Focus Statistics
              _buildFocusStatistics(focusService),
              const SizedBox(height: 24),

              // App Usage Statistics
              _buildAppUsageStatistics(),
              const SizedBox(height: 24),
              // Productivity Score
              _buildProductivityScore(focusService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Chọn thời gian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPeriodButton('today', 'Hôm nay'),
              const SizedBox(width: 8),
              _buildPeriodButton('week', 'Tuần này'),
              const SizedBox(width: 8),
              _buildPeriodButton('month', 'Tháng này'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(AppConstants.primaryColor) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 44), // Đảm bảo chiều cao tối thiểu
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusStatistics(FocusService focusService) {
    final sessions = _getSessionsForPeriod(focusService);
    final totalFocusTime = sessions.fold<Duration>(
      Duration.zero,
      (total, session) {
        // Tính toán actualFocusMinutes chính xác
        int actualMinutes;
        if (session.status == SessionStatus.completed || session.status == SessionStatus.cancelled) {
          actualMinutes = session.actualFocusMinutes ?? session.calculateActualFocusTime();
        } else {
          actualMinutes = session.calculateActualFocusTime();
        }
        return total + Duration(minutes: actualMinutes);
      },
    );
    final totalSessions = sessions.length;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Color(AppConstants.primaryColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê tập trung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng thời gian',
                  _formatDuration(totalFocusTime),
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Số phiên',
                  totalSessions.toString(),
                  Icons.history,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Trung bình/phiên',
                  totalSessions > 0 
                      ? _formatDuration(Duration(minutes: _calculateAverageSessionTime(sessions)))
                      : '0 phút',
                  Icons.analytics,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Hiệu suất',
                  '${_calculateOverallPerformance(sessions)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sử dụng ứng dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Thêm button để check permission
              IconButton(
                onPressed: _checkAndRequestUsagePermission,
                icon: const Icon(Icons.settings),
                tooltip: 'Kiểm tra quyền truy cập',
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, Duration>>(
            future: _getAppUsageForPeriod(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Không thể tải dữ liệu sử dụng ứng dụng'),
                );
              }

              final appUsage = snapshot.data ?? {};
              final totalUsage = appUsage.values.fold<Duration>(
                Duration.zero,
                (total, duration) => total + duration,
              );

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tổng thời gian',
                          _formatDuration(totalUsage),
                          Icons.timer,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Số ứng dụng',
                          appUsage.length.toString(),
                          Icons.apps,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (appUsage.isNotEmpty) ...[
                    const Text(
                      'Top ứng dụng sử dụng nhiều nhất:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...appUsage.entries
                        .take(5)
                        .map((entry) => _buildAppUsageItem(entry.key, entry.value)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

 
  Widget _buildProductivityScore(FocusService focusService) {
    final sessions = _getSessionsForPeriod(focusService);
    final productivityScore = _calculateProductivityScore(sessions);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColor),
            const Color(AppConstants.primaryColor).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Điểm hiệu suất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$productivityScore%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProductivityMessage(productivityScore),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildHistoryTab() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        final sessions = _getSessionsForPeriod(focusService);
        
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có lịch sử phiên tập trung',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hãy bắt đầu phiên tập trung để xem lịch sử',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Color(AppConstants.primaryColor),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.goal ?? 'Phiên tập trung',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(session.startTime),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: session.isCompleted ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session.isCompleted ? 'Hoàn thành' : 'Chưa hoàn thành',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHistoryStatItem(
                          'Thời gian',
                          _formatDuration(Duration(minutes: session.durationMinutes)),
                          Icons.timer,
                        ),
                      ),
                      Expanded(
                        child: _buildHistoryStatItem(
                          'Thực tế',
                          '${_calculateActualFocusMinutes(session)} phút',
                          Icons.flag,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildHistoryStatItem(
                          'Hiệu suất',
                          '${_calculatePerformancePercentage(session)}%',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageItem(String appName, Duration duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.phone_android, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Helper methods
  List<dynamic> _getSessionsForPeriod(FocusService focusService) {
    final now = DateTime.now();
          final sessions = focusService.sessions?.where((session) {
      switch (_selectedPeriod) {
        case 'today':
          return session.startTime.day == now.day &&
                 session.startTime.month == now.month &&
                 session.startTime.year == now.year;
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return session.startTime.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'month':
          return session.startTime.month == now.month &&
                 session.startTime.year == now.year;
        default:
          return true;
      }
    }).toList() ?? [];
    return sessions;
  }

  Future<Map<String, Duration>> _getAppUsageForPeriod() async {
    final appUsageService = AppUsageService();
    return await appUsageService.getAppUsageForPeriod(_selectedPeriod);
  }
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  int _calculateProductivityScore(List<dynamic> sessions) {
    if (sessions.isEmpty) return 0;
    
    num totalScore = 0;
    for (final session in sessions) {
      // Tính completion rate dựa trên thời gian thực tế so với mục tiêu
      final actualTime = _calculateActualFocusMinutes(session);
      final completionRate = actualTime / session.durationMinutes;
      if (completionRate >= 1.0) {
        totalScore += 100;
      } else {
        totalScore += (completionRate * 100).round();
      }
    }
    
    return (totalScore / sessions.length).round().toInt();
  }

  int _calculateOverallPerformance(List<dynamic> sessions) {
    if (sessions.isEmpty) return 0;
    
    int totalActualMinutes = 0;
    int totalPlannedMinutes = 0;
    
    for (final session in sessions) {
      totalActualMinutes += _calculateActualFocusMinutes(session);
      final planned = session.durationMinutes;
      if (planned is int) {
        totalPlannedMinutes += planned;
      } else if (planned is num) {
        totalPlannedMinutes += planned.toInt();
      } else {
        totalPlannedMinutes += 0;
      }
    }
    
    if (totalPlannedMinutes <= 0) return 0;
    return ((totalActualMinutes / totalPlannedMinutes) * 100).round().toInt();
  }

  int _calculateAverageSessionTime(List<dynamic> sessions) {
    if (sessions.isEmpty) return 0;
    
    int totalActualMinutes = 0;
    for (final session in sessions) {
      totalActualMinutes += _calculateActualFocusMinutes(session);
    }
    
    return (totalActualMinutes / sessions.length).round().toInt();
  }

  String _getProductivityMessage(int score) {
    if (score >= 90) return 'Xuất sắc!';
    if (score >= 80) return 'Rất tốt!';
    if (score >= 70) return 'Tốt!';
    if (score >= 60) return 'Khá tốt';
    if (score >= 50) return 'Trung bình';
    return 'Cần cải thiện';
  }

  int _calculateActualFocusMinutes(dynamic session) {
    // Tính toán actualFocusMinutes chính xác
    if (session.status == SessionStatus.completed || session.status == SessionStatus.cancelled) {
      return session.actualFocusMinutes ?? session.calculateActualFocusTime();
    } else {
      return session.calculateActualFocusTime();
    }
  }

  // Di chuyển method này vào đây, TRƯỚC dấu đóng ngoặc của class
  Future<void> _checkAndRequestUsagePermission() async {
    final appBlockingService = AppBlockingService();
    final hasPermission = await appBlockingService.checkPermissions();
    
    if (!hasPermission) {
      // Show dialog to user
      final shouldRequest = await showDialog<bool>(
        context: context, // context available here
        builder: (context) => AlertDialog(
          title: const Text('Cần quyền truy cập'),
          content: const Text(
            'Để hiển thị thống kê sử dụng ứng dụng chính xác, '
            'FocusLock cần quyền "Usage Access". '
            'Bạn có muốn cấp quyền này không?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cấp quyền'),
            ),
          ],
        ),
      );
      
      if (shouldRequest == true) {
        await appBlockingService.requestUsageAccessPermission();
      }
    }
  }

  int _calculatePerformancePercentage(dynamic session) {
    final actualTime = _calculateActualFocusMinutes(session);
    if (actualTime <= 0 || session.durationMinutes <= 0) return 0;
    return ((actualTime / session.durationMinutes) * 100).round().toInt();
  }
} // Đóng class ở đây
