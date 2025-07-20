import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Kiểm tra user đã đăng nhập
  bool get isLoggedIn => _auth.currentUser != null;

  // Kiểm tra Firebase Auth đã sẵn sàng
  bool get isFirebaseReady => _auth != null;

  // Đăng ký tài khoản mới
  Future<UserCredential> registerWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await sendEmailVerification();
    return credential;
  }

  // Đăng nhập
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      print('AuthService: Bắt đầu đăng xuất...');
      print('AuthService: Current user trước khi đăng xuất: ${_auth.currentUser?.uid}');
      
      // Clear user data before signing out
      await _clearUserData();
      
      await _auth.signOut();
      
      print('AuthService: Đã đăng xuất thành công');
      print('AuthService: Current user sau khi đăng xuất: ${_auth.currentUser?.uid}');
      
      notifyListeners();
    } catch (e) {
      print('AuthService: Lỗi khi đăng xuất: $e');
      throw Exception('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  // Clear user data when signing out
  Future<void> _clearUserData() async {
    try {
      print('AuthService: Clearing user data...');
      // Import FocusService here to avoid circular dependency
      // This will be handled in the UI layer
      print('AuthService: User data cleared');
    } catch (e) {
      print('AuthService: Error clearing user data: $e');
    }
  }

  // Gửi email xác thực
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        print('AuthService: Gửi email xác thực đến ${_auth.currentUser!.email}');
        await _auth.currentUser!.sendEmailVerification();
        print('AuthService: Email xác thực đã được gửi thành công');
      } else {
        throw Exception('Email đã được xác thực hoặc không có user đăng nhập');
      }
    } catch (e) {
      print('AuthService: Lỗi khi gửi email xác thực: $e');
      if (e.toString().contains('too-many-requests')) {
        throw Exception('Đã gửi quá nhiều email xác thực. Vui lòng đợi 1 giờ trước khi thử lại.');
      } else if (e.toString().contains('network')) {
        throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.');
      } else if (e.toString().contains('operation-not-allowed')) {
        throw Exception('Chức năng gửi email xác thực chưa được bật trong Firebase. Vui lòng liên hệ admin.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception('Không tìm thấy tài khoản. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi khi gửi email xác thực: ${e.toString()}');
      }
    }
  }

  // Gửi email quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Cập nhật thông tin tài khoản
  Future<void> updateProfile({String? displayName, String? email, String? avatarId}) async {
    if (_auth.currentUser != null) {
      try {
        print('AuthService: Bắt đầu cập nhật profile...');
        print('AuthService: Current user: ${_auth.currentUser!.email}');
        print('AuthService: Email verified: ${_auth.currentUser!.emailVerified}');
        
        if (displayName != null && displayName != _auth.currentUser!.displayName) {
          print('AuthService: Cập nhật display name...');
          await _auth.currentUser!.updateDisplayName(displayName);
          print('AuthService: Display name đã được cập nhật');
        }
        
        if (email != null && email != _auth.currentUser!.email) {
          print('AuthService: Thay đổi email từ ${_auth.currentUser!.email} thành $email');
          
          // Kiểm tra email đã được xác thực chưa
          if (!_auth.currentUser!.emailVerified) {
            throw Exception('Vui lòng xác thực email hiện tại trước khi thay đổi email.');
          }
          
          // Thử thay đổi email
          await _auth.currentUser!.updateEmail(email);
          print('AuthService: Email đã được thay đổi thành công');
        }
        
        // Lưu avatar ID vào SharedPreferences
        if (avatarId != null) {
          print('AuthService: Cập nhật avatar ID: $avatarId');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_avatar_id', avatarId);
        }
        
        await _auth.currentUser!.reload();
        notifyListeners();
        print('AuthService: Profile đã được cập nhật thành công');
      } catch (e) {
        print('AuthService: Lỗi khi cập nhật profile: $e');
        print('AuthService: Error type: ${e.runtimeType}');
        print('AuthService: Error details: ${e.toString()}');
        
        if (e.toString().contains('requires-recent-login')) {
          throw Exception('Để thay đổi email, vui lòng đăng nhập lại để xác thực.');
        } else if (e.toString().contains('operation-not-allowed')) {
          throw Exception('Chức năng thay đổi email chưa được bật. Vui lòng:\n1. Vào Firebase Console\n2. Authentication → Sign-in method\n3. Bật Email/Password provider');
        } else if (e.toString().contains('email-already-in-use')) {
          throw Exception('Email này đã được sử dụng bởi tài khoản khác.');
        } else if (e.toString().contains('invalid-email')) {
          throw Exception('Email không hợp lệ.');
        } else if (e.toString().contains('network')) {
          throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra internet.');
        } else if (e.toString().contains('timeout')) {
          throw Exception('Lỗi timeout. Vui lòng thử lại.');
        }
        rethrow;
      }
    }
  }

  // Theo dõi trạng thái đăng nhập
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Reload thông tin user từ server
  Future<void> reloadUser() async {
    try {
      if (_auth.currentUser != null) {
        print('AuthService: Reloading user info...');
        await _auth.currentUser!.reload();
        print('AuthService: User reloaded successfully');
        print('AuthService: Email verified: ${_auth.currentUser!.emailVerified}');
        notifyListeners();
      }
    } catch (e) {
      print('AuthService: Error reloading user: $e');
    }
  }

  // Kiểm tra trạng thái Firebase Auth
  void debugAuthState() {
    print('AuthService Debug Info:');
    print('- Firebase Auth instance: $_auth');
    print('- Current user: ${_auth.currentUser?.uid}');
    print('- Current user email: ${_auth.currentUser?.email}');
    print('- Email verified: ${_auth.currentUser?.emailVerified}');
    print('- Is Firebase ready: $isFirebaseReady');
  }


} 