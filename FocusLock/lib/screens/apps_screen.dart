import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../services/app_usage_service.dart';
import '../services/social_media_service.dart';
import '../services/app_blocking_service.dart';
import '../models/app_info.dart';
import '../utils/constants.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  final AppBlockingService _appBlockingService = AppBlockingService();
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy danh sách app thực tế đã cài trên máy
      _allApps = await _appBlockingService.getInstalledApps();
      _filteredApps = List.from(_allApps);
    } catch (e) {
      print('Error loading installed apps: $e');
      _allApps = [];
      _filteredApps = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = List.from(_allApps);
      } else {
        _filteredApps = _allApps
            .where((app) =>
                app.appName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleAppBlock(AppInfo app) {
    setState(() {
      final index = _allApps.indexWhere((a) => a.packageName == app.packageName);
      if (index != -1) {
        _allApps[index] = app.copyWith(isBlocked: !app.isBlocked);
      }
      
      final filteredIndex = _filteredApps.indexWhere((a) => a.packageName == app.packageName);
      if (filteredIndex != -1) {
        _filteredApps[filteredIndex] = _filteredApps[filteredIndex].copyWith(isBlocked: !app.isBlocked);
      }
    });

    // Update in FocusService
    final focusService = Provider.of<FocusService>(context, listen: false);
    focusService.updateBlockedApps(_allApps);
  }

  void _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category;
    });
    
    await _filterAppsByCategory(category);
    setState(() {}); // Rebuild UI sau khi filter
  }

  Future<void> _filterAppsByCategory(String category) async {
    print('AppsScreen: Filtering category: $category, total apps: ${_allApps.length}');
    
    if (category == 'all') {
      _filteredApps = List.from(_allApps);
      print('AppsScreen: All apps - ${_filteredApps.length} apps');
    } else {
      // Sử dụng AppUsageService để phân loại với danh sách thực tế
      final appUsageService = AppUsageService();
      _filteredApps = await appUsageService.getAppsByCategory(category, appsList: _allApps);
      print('AppsScreen: $category category - ${_filteredApps.length} apps');
      
      // Debug: In ra tên các app trong danh mục
      for (final app in _filteredApps) {
        print('AppsScreen: $category - ${app.appName} (${app.packageName})');
      }
    }
  }

  Widget _buildCategoryButton(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppConstants.primaryColor) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(AppConstants.primaryColor) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Ứng dụng bị chặn'),
        backgroundColor: const Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: _filterApps,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ứng dụng...',
                prefixIcon: const Icon(Icons.search),
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
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Category buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryButton('all', 'Tất cả', Icons.apps),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCategoryButton('social', 'Xã hội', Icons.people),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCategoryButton('entertainment', 'Giải trí', Icons.movie),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCategoryButton('gaming', 'Game', Icons.games),
                ),
              ],
            ),
          ),
          
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(AppConstants.primaryColor).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(AppConstants.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Các ứng dụng được chọn sẽ bị chặn trong thời gian tập trung',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Apps list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return _buildAppTile(app);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy ứng dụng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile(AppInfo app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: app.isBlocked 
              ? const Color(AppConstants.errorColor).withOpacity(0.1)
              : Colors.grey[100],
          child: Icon(
            _getAppIcon(app.packageName),
            color: app.isBlocked 
                ? const Color(AppConstants.errorColor)
                : Colors.grey[600],
          ),
        ),
        title: Text(
          app.appName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: app.isBlocked ? const Color(AppConstants.errorColor) : null,
          ),
        ),
        subtitle: Text(
          app.isBlocked ? 'Sẽ bị chặn' : 'Được phép sử dụng',
          style: TextStyle(
            color: app.isBlocked 
                ? const Color(AppConstants.errorColor)
                : Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: app.isBlocked,
          onChanged: (value) => _toggleAppBlock(app),
          activeColor: const Color(AppConstants.errorColor),
        ),
      ),
    );
  }

  IconData _getAppIcon(String packageName) {
    switch (packageName) {
      case 'com.facebook.katana':
        return Icons.facebook;
      case 'com.instagram.android':
        return Icons.camera_alt;
      case 'com.zhiliaoapp.musically':
        return Icons.music_note;
      case 'com.twitter.android':
        return Icons.flutter_dash;
      case 'com.threads.android':
        return Icons.chat_bubble;
      case 'com.snapchat.android':
        return Icons.camera_alt;
      case 'com.whatsapp':
        return Icons.chat;
      case 'com.telegram.messenger':
        return Icons.send;
      case 'com.discord':
        return Icons.games;
      case 'com.reddit.frontpage':
        return Icons.forum;
      case 'com.pinterest':
        return Icons.bookmark;
      case 'com.linkedin.android':
        return Icons.work;
      case 'com.spotify.music':
        return Icons.music_note;
      case 'com.netflix.mediaclient':
        return Icons.movie;
      case 'com.google.android.youtube':
        return Icons.play_circle_filled;
      default:
        return Icons.apps;
    }
  }
} 