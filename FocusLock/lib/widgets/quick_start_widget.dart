import 'package:flutter/material.dart';
import '../utils/constants.dart';

class QuickStartWidget extends StatefulWidget {
  final Function(int duration, String? goal) onStartSession;
  final bool hasSelectedApps;

  const QuickStartWidget({
    super.key,
    required this.onStartSession,
    this.hasSelectedApps = false,
  });

  @override
  State<QuickStartWidget> createState() => _QuickStartWidgetState();
}

class _QuickStartWidgetState extends State<QuickStartWidget> {
  int _selectedDuration = 5;
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _customTimeController = TextEditingController();
  bool _isCustomTime = false;

  @override
  void dispose() {
    _goalController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

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
                  Icons.play_arrow,
                  color: Color(AppConstants.primaryColor),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bắt đầu nhanh',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Duration selection
          const Text(
            'Thời gian tập trung',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Predefined durations
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...AppConstants.defaultDurations.map((duration) {
                final isSelected = duration == _selectedDuration && !_isCustomTime;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDuration = duration;
                      _isCustomTime = false;
                      _customTimeController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(AppConstants.primaryColor)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '${duration} phút',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              // Custom time button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomTime = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCustomTime 
                        ? const Color(AppConstants.primaryColor)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: _isCustomTime
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: _isCustomTime ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tùy chỉnh',
                        style: TextStyle(
                          color: _isCustomTime ? Colors.white : Colors.grey[700],
                          fontWeight: _isCustomTime ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Custom time input field
          if (_isCustomTime) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Nhập số phút (1-999)',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(AppConstants.primaryColor),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixText: 'phút',
                      suffixStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final customDuration = int.tryParse(value);
                        if (customDuration != null && customDuration > 0 && customDuration <= 999) {
                          setState(() {
                            _selectedDuration = customDuration;
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            
            // Validation message
            if (_customTimeController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final customDuration = int.tryParse(_customTimeController.text);
                  if (customDuration == null || customDuration <= 0) {
                    return Text(
                      'Vui lòng nhập số phút hợp lệ (lớn hơn 0)',
                      style: TextStyle(
                        color: const Color(AppConstants.errorColor),
                        fontSize: 12,
                      ),
                    );
                  } else if (customDuration > 999) {
                    return Text(
                      'Thời gian tối đa là 999 phút',
                      style: TextStyle(
                        color: const Color(AppConstants.errorColor),
                        fontSize: 12,
                      ),
                    );
                  } else {
                    return Text(
                      'Thời gian tập trung: $customDuration phút',
                      style: TextStyle(
                        color: const Color(AppConstants.successColor),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
          
          const SizedBox(height: 24),
          
          // Goal input
          const Text(
            'Mục tiêu (tùy chọn)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _goalController,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Hoàn thành bài tập, Đọc sách...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(AppConstants.primaryColor),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Validate custom time if selected
                if (_isCustomTime) {
                  final customDuration = int.tryParse(_customTimeController.text);
                  if (customDuration == null || customDuration <= 0 || customDuration > 999) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập thời gian hợp lệ (1-999 phút)'),
                        backgroundColor: Color(AppConstants.errorColor),
                      ),
                    );
                    return;
                  }
                }
                
                final goal = _goalController.text.trim().isEmpty 
                    ? null 
                    : _goalController.text.trim();
                widget.onStartSession(_selectedDuration, goal);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Bắt đầu tập trung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Warning if no apps selected
          if (!widget.hasSelectedApps)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: const Color(0xFFFF9800),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chưa chọn ứng dụng nào',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vào tab "Ứng dụng" để chọn các app muốn chặn trong thời gian tập trung',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (!widget.hasSelectedApps) const SizedBox(height: 16),
          
          // Quick tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mẹo: Bắt đầu với 5 phút để làm quen, sau đó tăng dần thời gian',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}