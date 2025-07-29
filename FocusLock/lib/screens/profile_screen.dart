
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const ProfileScreen({Key? key, this.onRestart}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _emailVerificationCooldown = false;
  String? _message;
  static const platform = MethodChannel('focuslock/app_blocking');
  Key _avatarKey = UniqueKey(); // Thêm key để force rebuild
  Timer? _emailCheckTimer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationCooldown();
    _setupAutoEmailVerificationCheck();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserInfo();
    });
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAutoEmailVerificationCheck() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Lắng nghe thay đổi auth state
    _authSubscription = authService.authStateChanges().listen((user) {
      if (mounted && user != null) {
        // Nếu email đã xác thực, dừng timer
        if (user.emailVerified) {
          _emailCheckTimer?.cancel();
        } else {
          // Nếu chưa xác thực, bắt đầu kiểm tra định kỳ
          _startPeriodicCheck();
        }
      }
    });
  }

  void _startPeriodicCheck() {
    _emailCheckTimer?.cancel(); // Hủy timer cũ nếu có
    
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.reloadUser();
        
        if (authService.currentUser?.emailVerified == true) {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Email đã được xác thực thành công!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        print('Lỗi khi kiểm tra email verification: $e');
      }
    });
  }

  Future<void> _checkEmailVerificationCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmailVerificationTime =
        prefs.getInt('last_email_verification_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = currentTime - lastEmailVerificationTime;

    // Nếu chưa đủ 60 giây kể từ lần gửi email cuối
    if (timeDiff < 60000) {
      setState(() {
        _emailVerificationCooldown = true;
      });

      // Tính thời gian còn lại
      final remainingSeconds = (60000 - timeDiff) ~/ 1000;

      // Tự động tắt cooldown sau thời gian còn lại
      Future.delayed(Duration(seconds: remainingSeconds), () {
        if (mounted) {
          setState(() {
            _emailVerificationCooldown = false;
          });
        }
      });
    }
  }

  Future<void> _refreshUserInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.reloadUser();
      
      // Force rebuild avatar FutureBuilder
      setState(() {
        _avatarKey = UniqueKey();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã làm mới thông tin tài khoản'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi làm mới: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getInitials(String? displayName, String? email) {
    String text = displayName ?? email ?? 'U';
    if (text.isEmpty) return 'U';
    return text.substring(0, 1).toUpperCase();
  }

  // Lấy thông tin avatar từ SharedPreferences theo user ID với debug
  Future<String> _getUserAvatar() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = user.uid;
        
        // Debug logs chi tiết
        print('ProfileScreen: Getting avatar for user: $userId');
        print('ProfileScreen: All SharedPreferences keys: ${prefs.getKeys()}');
        
        // Kiểm tra tất cả keys có chứa user ID
        final allKeys = prefs.getKeys();
        final userKeys = allKeys.where((key) => key.contains(userId)).toList();
        print('ProfileScreen: Keys containing user ID: $userKeys');
        
        final avatarId = prefs.getString('user_avatar_id_$userId') ?? 'default';
        print('ProfileScreen: Retrieved avatar ID: $avatarId');
        
        // Kiểm tra trực tiếp key cụ thể
        final specificKey = 'user_avatar_id_$userId';
        final hasKey = prefs.containsKey(specificKey);
        print('ProfileScreen: Key \"$specificKey\" exists: $hasKey');
        
        print('ProfileScreen: Found avatar: $avatarId for user: $userId');
        return avatarId;
      }
      
      print('ProfileScreen: No user found, returning default avatar');
      return 'default';
    } catch (e) {
      print('ProfileScreen: Error getting avatar: $e');
      return 'default';
    }
  }

  // Danh sách avatar có sẵn (giống như trong edit_profile_screen.dart)
  final List<Map<String, dynamic>> _avatars = [
    {'id': 'default', 'icon': Icons.person, 'color': Colors.blue, 'name': 'Mặc định'},
    {'id': 'user1', 'icon': Icons.face, 'color': Colors.green, 'name': 'Mặt cười'},
    {'id': 'user2', 'icon': Icons.person_outline, 'color': Colors.purple, 'name': 'Người dùng'},
    {'id': 'user3', 'icon': Icons.account_circle, 'color': Colors.orange, 'name': 'Tài khoản'},
    {'id': 'user4', 'icon': Icons.supervised_user_circle, 'color': Colors.teal, 'name': 'Quản lý'},
    {'id': 'user5', 'icon': Icons.verified_user, 'color': Colors.indigo, 'name': 'Xác thực'},
    {'id': 'user6', 'icon': Icons.psychology, 'color': Colors.pink, 'name': 'Thông minh'},
    {'id': 'user7', 'icon': Icons.sports_esports, 'color': Colors.red, 'name': 'Game'},
    {'id': 'user8', 'icon': Icons.work, 'color': Colors.brown, 'name': 'Công việc'},
  ];

  // Lấy thông tin avatar để hiển thị
  Widget _buildUserAvatar(String avatarId) {
    // Tìm avatar trong danh sách
    final avatar = _avatars.firstWhere(
      (a) => a['id'] == avatarId,
      orElse: () => _avatars[0], // default avatar nếu không tìm thấy
    );
    
    return CircleAvatar(
      radius: 50,
      backgroundColor: avatar['color'],
      child: Icon(
        avatar['icon'],
        color: Colors.white,
        size: 50,
      ),
    );
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();

      // Lưu thời gian gửi email để tránh spam
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_email_verification_time',
        DateTime.now().millisecondsSinceEpoch,
      );

      setState(() {
        _message =
            'Đã gửi email xác thực đến ${authService.currentUser?.email}';
      });

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email xác thực đã được gửi đến ${authService.currentUser?.email}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi: ${e.toString()}';
      });

      // Hiển thị thông báo lỗi chi tiết
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('too-many-requests')) {
          errorMessage =
              'Đã gửi quá nhiều email xác thực. Vui lòng đợi 1 giờ trước khi thử lại.';
          // Bật cooldown cho nút gửi email
          setState(() {
            _emailVerificationCooldown = true;
          });
          // Tự động tắt cooldown sau 60 giây
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted) {
              setState(() {
                _emailVerificationCooldown = false;
              });
            }
          });
        } else if (errorMessage.contains('network')) {
          errorMessage =
              'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
        } else if (errorMessage.contains('operation-not-allowed')) {
          errorMessage =
              'Chức năng gửi email xác thực chưa được bật. Vui lòng liên hệ admin để bật trong Firebase Console.';
        } else if (errorMessage.contains('user-not-found')) {
          errorMessage = 'Không tìm thấy tài khoản. Vui lòng đăng nhập lại.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        widget.onRestart?.call(); // Gọi trước khi pop để tránh lỗi navigation
        Navigator.of(context).pop(); // Pop sau
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    key: _avatarKey, // Thêm key để force rebuild
                    future: _getUserAvatar(),
                    builder: (context, snapshot) {
                      final avatarId = snapshot.data ?? 'default';
                      return Row(
                        children: [
                          _buildUserAvatar(avatarId),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Chưa đặt tên',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user.email ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (user.emailVerified)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Email đã xác thực',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Email chưa xác thực',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Trạng thái sẽ tự động cập nhật',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Thông tin bổ sung về tài khoản
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ID tài khoản:'),
                            Text(
                              user.uid.length > 8
                                  ? user.uid.substring(0, 8) + '...'
                                  : user.uid,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ngày tạo:'),
                            Text(
                              user.metadata.creationTime != null
                                  ? '${user.metadata.creationTime!.day}/${user.metadata.creationTime!.month}/${user.metadata.creationTime!.year}'
                                  : 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lần đăng nhập cuối:'),
                            Text(
                              user.metadata.lastSignInTime != null
                                  ? '${user.metadata.lastSignInTime!.day}/${user.metadata.lastSignInTime!.month}/${user.metadata.lastSignInTime!.year}'
                                  : 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_message != null)
                    Text(
                      _message!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa thông tin'),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  );
                                  // Refresh avatar sau khi quay về từ EditProfile
                                  if (result == true) {
                                    setState(() {
                                      _avatarKey = UniqueKey();
                                    });
                                  }
                                },
                        ),
                      ),
                      
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!user.emailVerified) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,  // Thay đổi từ Colors.orange.shade50
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),  // Thay đổi từ Colors.orange.shade200
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,  // Thay đổi từ Icons.warning
                                color: Colors.blue.shade700,  // Thay đổi từ Colors.orange.shade700
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xác thực email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,  // Thay đổi từ Colors.orange.shade700
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng xác thực email để sử dụng đầy đủ tính năng của ứng dụng.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.verified_user),
                              label: Text(
                                _emailVerificationCooldown
                                    ? 'Đợi...'
                                    : 'Gửi email xác thực',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _emailVerificationCooldown
                                    ? Colors.grey
                                    : Colors.blue,  // Thay đổi từ Colors.orange
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed:
                                  (_isLoading || _emailVerificationCooldown)
                                  ? null
                                  : _sendEmailVerification,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Đổi mật khẩu'),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _isLoading ? null : _signOut,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
