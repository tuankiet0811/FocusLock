import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_service.dart';
import '../services/app_usage_service.dart';
import '../services/social_media_service.dart';
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
  final AppUsageService _appUsageService = AppUsageService();
  final SocialMediaService _socialMediaService = SocialMediaService();
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
      // Get all available apps from service
      _allApps = await _appUsageService.getAllApps();
      
      // Add social media apps if not already present
      final socialMediaApps = _socialMediaService.getSocialMediaApps();
      for (final socialApp in socialMediaApps) {
        final existingIndex = _allApps.indexWhere((app) => app.packageName == socialApp.packageName);
        if (existingIndex == -1) {
          _allApps.add(socialApp);
        }
      }
      
      _filteredApps = List.from(_allApps);
    } catch (e) {
      print('Error loading apps: $e');
      // Fallback to social media apps only
      _allApps = _socialMediaService.getPopularSocialMediaApps();
      _filteredApps = List.from(_allApps);
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

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterAppsByCategory(category);
    });
  }

  void _filterAppsByCategory(String category) {
    switch (category) {
      case 'social':
        _filteredApps = _allApps.where((app) => 
          _socialMediaService.isSocialMediaApp(app.packageName)
        ).toList();
        break;
      case 'messaging':
        final messagingApps = _socialMediaService.getMessagingApps();
        _filteredApps = _allApps.where((app) => 
          messagingApps.any((msgApp) => msgApp.packageName == app.packageName)
        ).toList();
        break;
      case 'video':
        final videoApps = _socialMediaService.getVideoEntertainmentApps();
        _filteredApps = _allApps.where((app) => 
          videoApps.any((videoApp) => videoApp.packageName == app.packageName)
        ).toList();
        break;
      case 'popular':
        final popularApps = _socialMediaService.getPopularSocialMediaApps();
        _filteredApps = _allApps.where((app) => 
          popularApps.any((popApp) => popApp.packageName == app.packageName)
        ).toList();
        break;
      default:
        _filteredApps = List.from(_allApps);
        break;
    }
  }

  Widget _buildCategoryButton(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppConstants.primaryColor) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(AppConstants.primaryColor) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryButton('all', 'Tất cả', Icons.apps),
                  const SizedBox(width: 8),
                  _buildCategoryButton('social', 'Mạng xã hội', Icons.people),
                  const SizedBox(width: 8),
                  _buildCategoryButton('messaging', 'Tin nhắn', Icons.message),
                  const SizedBox(width: 8),
                  _buildCategoryButton('video', 'Video/Giải trí', Icons.video_library),
                  const SizedBox(width: 8),
                  _buildCategoryButton('popular', 'Phổ biến', Icons.trending_up),
                ],
              ),
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