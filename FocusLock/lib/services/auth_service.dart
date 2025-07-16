import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

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
    await _auth.signOut();
  }

  // Gửi email xác thực
  Future<void> sendEmailVerification() async {
    if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
      await _auth.currentUser!.sendEmailVerification();
    }
  }

  // Gửi email quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Cập nhật thông tin tài khoản
  Future<void> updateProfile({String? displayName, String? email}) async {
    if (_auth.currentUser != null) {
      if (displayName != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
      if (email != null) {
        await _auth.currentUser!.updateEmail(email);
      }
      await _auth.currentUser!.reload();
      notifyListeners();
    }
  }

  // Theo dõi trạng thái đăng nhập
  Stream<User?> authStateChanges() => _auth.authStateChanges();
} 