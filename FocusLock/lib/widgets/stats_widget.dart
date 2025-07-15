import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class StatsWidget extends StatelessWidget {
  final int todayFocusTime;
  final int thisWeekFocusTime;
  final int totalSessions;

  const StatsWidget({
    super.key,
    required this.todayFocusTime,
    required this.thisWeekFocusTime,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(AppConstants.primaryColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats Grid
          Row(
            children: [
              // Today's focus time
              Expanded(
                child: _buildStatCard(
                  icon: Icons.today,
                  title: 'Hôm nay',
                  value: Helpers.formatDuration(todayFocusTime),
                  color: const Color(AppConstants.primaryColor),
                  subtitle: 'Thời gian tập trung',
                ),
              ),
              
              const SizedBox(width: 12),
              
              // This week's focus time
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_view_week,
                  title: 'Tuần này',
                  value: Helpers.formatDuration(thisWeekFocusTime),
                  color: const Color(AppConstants.successColor),
                  subtitle: 'Thời gian tập trung',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Total sessions
          _buildStatCard(
            icon: Icons.history,
            title: 'Tổng phiên',
            value: totalSessions.toString(),
            color: const Color(AppConstants.accentColor),
            subtitle: 'Phiên tập trung đã hoàn thành',
            fullWidth: true,
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicator
          if (todayFocusTime > 0) ...[
            const Text(
              'Tiến độ hôm nay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _calculateTodayProgress(),
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(AppConstants.primaryColor),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_calculateTodayProgress() * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Mục tiêu: 2 giờ mỗi ngày',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTodayProgress() {
    // Assuming 2 hours (120 minutes) as daily goal
    const dailyGoal = 120;
    return (todayFocusTime / dailyGoal).clamp(0.0, 1.0);
  }
} 