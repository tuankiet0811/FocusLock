import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    if (_formKey.currentState!.validate()) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.changePasswordWithOldPassword(
          _oldPasswordController.text.trim(),
          _newPasswordController.text.trim(),
        );
        setState(() {
          _message = 'Đổi mật khẩu thành công!';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _message = e.toString();
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu cũ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (value.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                  if (value == _oldPasswordController.text) return 'Mật khẩu mới phải khác mật khẩu cũ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_message != null)
                Text(_message!, style: TextStyle(color: _message!.contains('thành công') ? Colors.green : Colors.red)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đổi mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 