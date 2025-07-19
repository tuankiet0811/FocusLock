import 'package:intl/intl.dart';

class Helpers {
  // Format duration from minutes to readable string
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours giờ';
      } else {
        return '$hours giờ $remainingMinutes phút';
      }
    }
  }

  // Format time remaining
  static String formatTimeRemaining(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Get percentage of completion
  static double getCompletionPercentage(DateTime startTime, DateTime endTime, DateTime currentTime) {
    if (currentTime.isBefore(startTime)) return 0.0;
    if (currentTime.isAfter(endTime)) return 100.0;
    
    int totalDuration = endTime.difference(startTime).inSeconds;
    int elapsed = currentTime.difference(startTime).inSeconds;
    
    return (elapsed / totalDuration) * 100;
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Get motivational message based on completion percentage
  static String getMotivationalMessage(double percentage) {
    if (percentage < 25) {
      return 'Bắt đầu là bước quan trọng nhất!';
    } else if (percentage < 50) {
      return 'Bạn đang làm rất tốt! Hãy tiếp tục!';
    } else if (percentage < 75) {
      return 'Đã được một nửa rồi! Cố gắng lên!';
    } else if (percentage < 100) {
      return 'Gần hoàn thành rồi! Đừng bỏ cuộc!';
    } else {
      return 'Tuyệt vời! Bạn đã hoàn thành!';
    }
  }

  // Get emoji based on completion percentage
  static String getMotivationalEmoji(double percentage) {
    if (percentage < 25) {
      return '🚀';
    } else if (percentage < 50) {
      return '💪';
    } else if (percentage < 75) {
      return '🔥';
    } else if (percentage < 100) {
      return '🎯';
    } else {
      return '🎉';
    }
  }

  // Calculate total focus time from sessions (sử dụng thời gian thực tế)
  static int calculateTotalFocusTime(List<dynamic> sessions) {
    int totalMinutes = 0;
    for (var session in sessions) {
      if (session is Map<String, dynamic>) {
        // Sử dụng actualFocusMinutes nếu có, không thì dùng durationMinutes
        final actualMinutes = session['actualFocusMinutes'] ?? session['durationMinutes'];
        if (actualMinutes != null) {
          totalMinutes += actualMinutes as int;
        }
      }
    }
    return totalMinutes;
  }

  // Get today's sessions
  static List<dynamic> getTodaySessions(List<dynamic> sessions) {
    DateTime today = DateTime.now();
    return sessions.where((session) {
      if (session is Map<String, dynamic> && session['startTime'] != null) {
        DateTime sessionDate = DateTime.parse(session['startTime']);
        return sessionDate.year == today.year &&
               sessionDate.month == today.month &&
               sessionDate.day == today.day;
      }
      return false;
    }).toList();
  }

  // Get this week's sessions
  static List<dynamic> getThisWeekSessions(List<dynamic> sessions) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return sessions.where((session) {
      if (session is Map<String, dynamic> && session['startTime'] != null) {
        DateTime sessionDate = DateTime.parse(session['startTime']);
        return sessionDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      }
      return false;
    }).toList();
  }
} 