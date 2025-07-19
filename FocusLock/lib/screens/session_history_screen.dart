import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/focus_service.dart';
import '../services/statistics_service.dart';
import '../models/focus_session.dart';
import '../models/session_history.dart';
import '../utils/constants.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';
  FocusSession? _selectedSession;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Lịch sử & Thống kê'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // Debug: Print current history
              final focusService = Provider.of<FocusService>(context, listen: false);
              final statisticsService = Provider.of<StatisticsService>(context, listen: false);
              statisticsService.debugPrintHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã in debug history vào console'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Debug History',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () async {
              // Cleanup duplicate history
              final statisticsService = Provider.of<StatisticsService>(context, listen: false);
              await statisticsService.cleanupDuplicateHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã dọn dẹp history trùng lặp'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Cleanup History Duplicates',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              // Cleanup duplicate sessions
              final focusService = Provider.of<FocusService>(context, listen: false);
              await focusService.cleanupDuplicateSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã dọn dẹp sessions trùng lặp'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Cleanup Session Duplicates',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              // Debug current session info
              final focusService = Provider.of<FocusService>(context, listen: false);
              final currentSession = focusService.currentSession;
              if (currentSession != null) {
                print('=== DEBUG SESSION INFO ===');
                print('Session ID: ${currentSession.id}');
                print('Start Time: ${currentSession.startTime}');
                print('End Time: ${currentSession.endTime}');
                print('Duration: ${currentSession.durationMinutes} minutes');
                print('Status: ${currentSession.status}');
                print('Total Pause Time: ${currentSession.totalPauseTimeMinutes} minutes');
                print('Actual Focus Time: ${currentSession.calculateActualFocusTime()} minutes');
                print('Pause History: ${currentSession.pauseHistory.length} entries');
                for (int i = 0; i < currentSession.pauseHistory.length; i++) {
                  final pause = currentSession.pauseHistory[i];
                  print('  Pause $i: ${pause.pauseTime} -> ${pause.resumeTime} (${pause.durationMinutes}m)');
                }
                print('========================');
              }
            },
            tooltip: 'Debug Session Info',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () async {
              // Auto cleanup duplicates
              final focusService = Provider.of<FocusService>(context, listen: false);
              await focusService.autoCleanupDuplicates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tự động dọn dẹp sessions trùng lặp'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Auto Cleanup Duplicates',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Lịch sử'),
            Tab(text: 'Thống kê'),
            Tab(text: 'Chi tiết'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildStatisticsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        final sessions = _getSessionsForPeriod(focusService.sessions);
        
        return Column(
          children: [
            _buildPeriodSelector(),
            Expanded(
              child: sessions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _buildSessionCard(session, focusService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        final statistics = focusService.getCurrentStatistics();
        final insights = focusService.getProductivityInsights();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              
              if (statistics != null) ...[
                _buildStatisticsCard(statistics),
                const SizedBox(height: 24),
                _buildInsightsCard(insights),
                const SizedBox(height: 24),
                _buildAppUsageCard(statistics),
              ] else
                _buildEmptyState(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return Consumer<FocusService>(
      builder: (context, focusService, child) {
        if (_selectedSession == null) {
          return _buildEmptyState(message: 'Chọn một phiên để xem chi tiết');
        }
        
        final sessionHistory = focusService.getSessionHistory(_selectedSession!.id);
        
        return Column(
          children: [
            _buildSessionHeader(_selectedSession!),
            Expanded(
              child: sessionHistory.isEmpty
                  ? _buildEmptyState(message: 'Không có lịch sử cho phiên này')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessionHistory.length,
                      itemBuilder: (context, index) {
                        final entry = sessionHistory[index];
                        return _buildHistoryEntryCard(entry);
                      },
                    ),
            ),
          ],
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
              _buildPeriodButton('all', 'Tất cả'),
              const SizedBox(width: 8),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildSessionCard(FocusSession session, FocusService focusService) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final duration = session.calculateActualFocusTime();
    final completionPercentage = session.calculateCompletionPercentage();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSession = session;
            _tabController.animateTo(2);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(session.status),
                    color: _getStatusColor(session.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.goal ?? 'Phiên tập trung',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _getStatusText(session.status),
                    style: TextStyle(
                      color: _getStatusColor(session.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${session.durationMinutes} phút',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$duration phút thực tế',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(session.startTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${(completionPercentage * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.primaryColor),
                    ),
                  ),
                ],
              ),
              if (session.totalPauseTimeMinutes > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.pause_circle, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tạm dừng: ${session.totalPauseTimeMinutes} phút',
                      style: TextStyle(color: Colors.orange[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(SessionStatistics statistics) {
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
                  Icons.analytics,
                  color: Color(AppConstants.primaryColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê tổng quan',
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
                child: _buildStatItem(
                  'Tổng thời gian',
                  '${statistics.totalFocusMinutes} phút',
                  Icons.timer,
                  const Color(AppConstants.primaryColor),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Tổng phiên',
                  '${statistics.totalSessions}',
                  Icons.play_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Hoàn thành',
                  '${statistics.completedSessions}',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tỷ lệ hoàn thành',
                  '${(statistics.completionRate * 100).round()}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Trung bình',
                  '${statistics.averageSessionLength.round()} phút',
                  Icons.av_timer,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Chuỗi hiện tại',
                  '${statistics.currentStreak}',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thông tin chi tiết',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (insights['focusEfficiency'] != null)
            _buildInsightItem(
              'Hiệu quả tập trung',
              '${insights['focusEfficiency']}%',
              Icons.psychology,
            ),
          if (insights['mostProductiveHour'] != null)
            _buildInsightItem(
              'Giờ hiệu quả nhất',
              '${insights['mostProductiveHour']}:00',
              Icons.schedule,
            ),
          if (insights['longestStreak'] != null)
            _buildInsightItem(
              'Chuỗi dài nhất',
              '${insights['longestStreak']} ngày',
              Icons.local_fire_department,
            ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageCard(SessionStatistics statistics) {
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ứng dụng bị chặn nhiều nhất',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (statistics.mostBlockedApps.isNotEmpty)
            ...statistics.mostBlockedApps.take(5).map((app) {
              final count = statistics.appBlockCounts[app] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        app,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '$count lần',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader(FocusSession session) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(
                _getStatusIcon(session.status),
                color: _getStatusColor(session.status),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.goal ?? 'Phiên tập trung',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu: ${dateFormat.format(session.startTime)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (session.endTime != null)
            Text(
              'Kết thúc: ${dateFormat.format(session.endTime!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Thời gian: ${session.durationMinutes} phút',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Text(
                'Thực tế: ${session.calculateActualFocusTime()} phút',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntryCard(SessionHistory entry) {
    final dateFormat = DateFormat('HH:mm:ss');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(entry.action).withOpacity(0.1),
          child: Icon(
            _getActionIcon(entry.action),
            color: _getActionColor(entry.action),
            size: 20,
          ),
        ),
        title: Text(
          _getActionText(entry.action),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateFormat.format(entry.timestamp),
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (entry.note != null)
              Text(
                entry.note!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: entry.data.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showDataDetails(entry),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState({String message = 'Không có dữ liệu'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<FocusSession> _getSessionsForPeriod(List<FocusSession> sessions) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'today':
        return sessions.where((session) {
          return session.startTime.day == now.day &&
                 session.startTime.month == now.month &&
                 session.startTime.year == now.year;
        }).toList();
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return sessions.where((session) {
          return session.startTime.isAfter(weekStart.subtract(const Duration(days: 1)));
        }).toList();
      case 'month':
        return sessions.where((session) {
          return session.startTime.month == now.month &&
                 session.startTime.year == now.year;
        }).toList();
      default:
        return sessions;
    }
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.running:
        return Icons.play_circle;
      case SessionStatus.paused:
        return Icons.pause_circle;
      case SessionStatus.completed:
        return Icons.check_circle;
      case SessionStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.running:
        return Colors.green;
      case SessionStatus.paused:
        return Colors.orange;
      case SessionStatus.completed:
        return Colors.blue;
      case SessionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.running:
        return 'Đang chạy';
      case SessionStatus.paused:
        return 'Tạm dừng';
      case SessionStatus.completed:
        return 'Hoàn thành';
      case SessionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  IconData _getActionIcon(SessionAction action) {
    switch (action) {
      case SessionAction.started:
        return Icons.play_arrow;
      case SessionAction.paused:
        return Icons.pause;
      case SessionAction.resumed:
        return Icons.play_arrow;
      case SessionAction.completed:
        return Icons.check;
      case SessionAction.cancelled:
        return Icons.cancel;
      case SessionAction.appBlocked:
        return Icons.block;
      case SessionAction.appUnblocked:
        return Icons.block_outlined;
      case SessionAction.goalSet:
        return Icons.flag;
      case SessionAction.goalAchieved:
        return Icons.emoji_events;
      case SessionAction.unknown:
        return Icons.help;
    }
  }

  Color _getActionColor(SessionAction action) {
    switch (action) {
      case SessionAction.started:
        return Colors.green;
      case SessionAction.paused:
        return Colors.orange;
      case SessionAction.resumed:
        return Colors.green;
      case SessionAction.completed:
        return Colors.blue;
      case SessionAction.cancelled:
        return Colors.red;
      case SessionAction.appBlocked:
        return Colors.red;
      case SessionAction.appUnblocked:
        return Colors.grey;
      case SessionAction.goalSet:
        return Colors.purple;
      case SessionAction.goalAchieved:
        return Colors.amber;
      case SessionAction.unknown:
        return Colors.grey;
    }
  }

  String _getActionText(SessionAction action) {
    switch (action) {
      case SessionAction.started:
        return 'Bắt đầu phiên';
      case SessionAction.paused:
        return 'Tạm dừng';
      case SessionAction.resumed:
        return 'Tiếp tục';
      case SessionAction.completed:
        return 'Hoàn thành';
      case SessionAction.cancelled:
        return 'Hủy bỏ';
      case SessionAction.appBlocked:
        return 'Chặn ứng dụng';
      case SessionAction.appUnblocked:
        return 'Bỏ chặn ứng dụng';
      case SessionAction.goalSet:
        return 'Đặt mục tiêu';
      case SessionAction.goalAchieved:
        return 'Đạt mục tiêu';
      case SessionAction.unknown:
        return 'Hành động không xác định';
    }
  }

  void _showDataDetails(SessionHistory entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionText(entry.action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entry.data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(entry.value.toString()),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
} 