import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRestart;
  const LoginScreen({Key? key, this.onRestart}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (_formKey.currentState!.validate()) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          widget.onRestart?.call();
        }
      } catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Thêm method mới để chuyển đổi lỗi Firebase thành thông báo thân thiện
  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Email này chưa được đăng ký. Vui lòng kiểm tra lại hoặc đăng ký tài khoản mới.';
    } else if (error.contains('wrong-password')) {
      return 'Mật khẩu không đúng. Vui lòng thử lại.';
    } else if (error.contains('invalid-email')) {
      return 'Định dạng email không hợp lệ.';
    } else if (error.contains('user-disabled')) {
      return 'Tài khoản này đã bị vô hiệu hóa.';
    } else if (error.contains('too-many-requests')) {
      return 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau.';
    } else if (error.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
    } else if (error.contains('invalid-credential')) {
      return 'Thông tin đăng nhập không đúng. Vui lòng kiểm tra email và mật khẩu.';
    } else if (error.contains('operation-not-allowed')) {
      return 'Phương thức đăng nhập này chưa được kích hoạt.';
    } else {
      return 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin và thử lại.';
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (value.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _goToRegister,
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                  TextButton(
                    onPressed: _goToForgotPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}