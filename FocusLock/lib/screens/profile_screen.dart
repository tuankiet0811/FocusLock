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

  @override
  void initState() {
    super.initState();
    _checkEmailVerificationCooldown();
    // Tự động reload user info khi mở profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserInfo();
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
      // 60 giây = 60000 milliseconds
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
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.reloadUser();

      setState(() {
        _message = 'Đã cập nhật thông tin tài khoản';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin tài khoản'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi khi cập nhật: ${e.toString()}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _changePassword(String email) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(email);
      setState(() {
        _message = 'Đã gửi email đổi mật khẩu đến $email';
      });
    } catch (e) {
      setState(() {
        _message = 'Lỗi: ${e.toString()}';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _getInitials(String? displayName, String? email) {
    String text = displayName ?? email ?? 'U';
    if (text.isEmpty) return 'U';
    return text.substring(0, 1).toUpperCase();
  }

  // Lấy thông tin avatar từ SharedPreferences
  Future<String> _getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_avatar_id') ?? 'default';
  }

  // Lấy thông tin avatar để hiển thị
  Widget _buildUserAvatar(String avatarId) {
    // Danh sách avatar tương tự như trong edit profile
    final Map<String, Map<String, dynamic>> avatars = {
      'default': {'icon': Icons.person, 'color': Colors.blue},
      'user1': {'icon': Icons.face, 'color': Colors.green},
      'user2': {'icon': Icons.person_outline, 'color': Colors.purple},
      'user3': {'icon': Icons.account_circle, 'color': Colors.orange},
      'user4': {'icon': Icons.supervised_user_circle, 'color': Colors.teal},
      'user5': {'icon': Icons.verified_user, 'color': Colors.indigo},
      'user6': {'icon': Icons.psychology, 'color': Colors.pink},
      'user7': {'icon': Icons.sports_esports, 'color': Colors.red},
      'user8': {'icon': Icons.work, 'color': Colors.brown},
    };

    final avatar = avatars[avatarId] ?? avatars['default']!;

    return CircleAvatar(
      radius: 32,
      backgroundColor: avatar['color'],
      child: Icon(avatar['icon'], color: Colors.white, size: 32),
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

  // Future<void> _requestOverlayPermission() async {
  //   try {
  //     final bool result = await platform.invokeMethod('requestPermissions');
  //     if (result) {
  //       setState(() {
  //         _message = 'Đã mở trang cấp quyền hiển thị trên ứng dụng khác.';
  //       });
  //     } else {
  //       setState(() {
  //         _message = 'Không thể mở trang cấp quyền. Vui lòng kiểm tra cài đặt.';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _message = 'Lỗi khi xin quyền overlay: \n${e.toString()}';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin tài khoản')),
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
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
                                        'Nhấn "Làm mới" sau khi xác thực email',
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
                  // Thông tin bổ sung về tài khoản (Moved up)
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
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Làm mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _refreshUserInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!user.emailVerified) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Xác thực email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
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
                                    : Colors.orange,
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
