// File: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; // Mới thêm

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Constructor: Cài đặt ngôn ngữ Tiếng Việt ngay khi khởi tạo Service
  AuthService() {
    _auth.setLanguageCode("vi");
  }

  // Stream để lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // 1. Đăng nhập bằng Email/Password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.setLanguageCode("vi");
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  // 2. Đăng ký bằng Email/Password
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.setLanguageCode("vi");
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  // 3. Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      await _auth.setLanguageCode("vi");

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('sign_in_canceled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('sign_in_canceled')) rethrow;
      throw Exception('Lỗi đăng nhập Google: ${e.toString()}');
    }
  }

  // 4. Đăng nhập bằng Facebook (MỚI THÊM)
  Future<User?> signInWithFacebook() async {
    try {
      await _auth.setLanguageCode("vi");

      // Kích hoạt đăng nhập Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;

        // Tạo credential
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        // Đăng nhập Firebase
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('sign_in_canceled');
      } else {
        throw Exception('Lỗi đăng nhập Facebook: ${result.message}');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('sign_in_canceled')) rethrow;
      throw Exception('Lỗi Facebook: ${e.toString()}');
    }
  }

  // 5. Đăng xuất (Đã cập nhật logout cả Facebook)
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Logout Firebase

      // Logout Google nếu đang dùng
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Logout Facebook (để lần sau có thể chọn tài khoản khác)
      await FacebookAuth.instance.logOut();

    } catch (e) {
      throw Exception('Không thể đăng xuất: ${e.toString()}');
    }
  }

  // 6. Gửi email Reset Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.setLanguageCode("vi");
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Không thể gửi email: ${e.toString()}');
    }
  }

  // 7. Kiểm tra user provider (Helper)
  bool isGoogleSignIn() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  // --- Xử lý lỗi Firebase Auth ---
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Không tìm thấy tài khoản với email này');
      case 'wrong-password':
        return Exception('Mật khẩu không chính xác');
      case 'email-already-in-use':
        return Exception('Email này đã được sử dụng');
      case 'account-exists-with-different-credential':
        return Exception('Email này đã đăng ký bằng phương thức khác (Google/Facebook)');
      case 'weak-password':
        return Exception('Mật khẩu quá yếu (cần >6 ký tự)');
      case 'invalid-email':
        return Exception('Email không hợp lệ');
      case 'user-disabled':
        return Exception('Tài khoản này đã bị vô hiệu hóa');
      case 'too-many-requests':
        return Exception('Quá nhiều yêu cầu. Vui lòng thử lại sau ít phút');
      case 'operation-not-allowed':
        return Exception('Lỗi hệ thống: Phương thức đăng nhập chưa bật');
      case 'network-request-failed':
        return Exception('Lỗi kết nối mạng. Kiểm tra Wifi/4G');
      case 'invalid-credential':
        return Exception('Thông tin xác thực không hợp lệ');
      default:
        return Exception('Lỗi: ${e.message ?? e.code}');
    }
  }
}