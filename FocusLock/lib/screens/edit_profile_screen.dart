import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  String _selectedAvatar = 'default';

  // Danh sách avatar có sẵn
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      // Load avatar từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedAvatar = prefs.getString('user_avatar_id') ?? 'default';
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        avatarId: _selectedAvatar, // Thêm avatar ID
      );
      
      setState(() {
        _message = 'Cập nhật thông tin thành công!';
      });

      // Hiển thị thông báo thành công và quay lại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi: ${e.toString()}';
      });
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildAvatarItem(Map<String, dynamic> avatar) {
    final isSelected = _selectedAvatar == avatar['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = avatar['id'];
        });
      },
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: avatar['color'],
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Icon(
          avatar['icon'],
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Avatar Selection
              const Text(
                'Chọn avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    return _buildAvatarItem(_avatars[index]);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Display Name Field
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  hintText: 'Nhập tên hiển thị',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên hiển thị';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Message display
              if (_message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.contains('Lỗi') ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('Lỗi') ? Colors.red.shade800 : Colors.green.shade800,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Cập nhật thông tin',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 