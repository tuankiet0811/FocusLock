import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class FocusTimerWidget extends StatefulWidget {
  final int remainingSeconds;
  final double completionPercentage;
  final VoidCallback onStop;
  final VoidCallback onPauseOrResume;
  final bool isPaused;
  final DateTime? pausedTime;
  final String? goal;

  const FocusTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.completionPercentage,
    required this.onStop,
    required this.onPauseOrResume,
    required this.isPaused,
    this.pausedTime,
    this.goal,
  });

  @override
  State<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends State<FocusTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _pauseTimerController;
  int _pauseDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
    
    // Timer cho thời gian dừng đếm
    _pauseTimerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pauseTimerController.addListener(() {
      if (widget.isPaused && widget.pausedTime != null) {
        setState(() {
          _pauseDurationSeconds = DateTime.now().difference(widget.pausedTime!).inSeconds;
        });
      }
    });
    _pauseTimerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pauseTimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: widget.remainingSeconds);
    final timeString = Helpers.formatTimeRemaining(duration);
    final motivationalMessage = Helpers.getMotivationalMessage(widget.completionPercentage);
    final motivationalEmoji = Helpers.getMotivationalEmoji(widget.completionPercentage);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.primaryColor),
            Color(0xFF1976D2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Goal display (if exists)
          if (widget.goal != null && widget.goal!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.goal!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Progress Circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: widget.completionPercentage / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      // Time display
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Còn lại',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Motivational message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  motivationalEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  motivationalMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress percentage and pause info
          Column(
            children: [
              Text(
                '${widget.completionPercentage.toInt()}% hoàn thành',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              if (widget.isPaused && _pauseDurationSeconds > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pause_circle,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã dừng: ${Helpers.formatTimeRemaining(Duration(seconds: _pauseDurationSeconds))}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pause/Resume button
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: widget.onPauseOrResume,
                    icon: widget.isPaused ? const Icon(Icons.play_arrow) : const Icon(Icons.pause),
                    label: Text(widget.isPaused ? 'Tiếp tục' : 'Tạm dừng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Stop button
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('FocusTimerWidget: Nút dừng được bấm, isPaused: ${widget.isPaused}');
                      _showStopConfirmation();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppConstants.errorColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStopConfirmation() {
    print('FocusTimerWidget: Hiển thị dialog dừng session');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dừng phiên tập trung?'),
        content: const Text(
          'Bạn có chắc chắn muốn dừng phiên tập trung hiện tại? '
          'Tiến độ sẽ không được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              print('FocusTimerWidget: Người dùng xác nhận dừng session');
              Navigator.of(context).pop();
              widget.onStop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.errorColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
  }
} 