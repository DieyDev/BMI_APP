import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  const UserAvatar({super.key, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius, color: Colors.grey),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        ImageProvider? imageProvider;

        // 1. ƯU TIÊN SỐ 1: Lấy từ Firestore (Ảnh mới nhất)
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          String? photoUrl = data['photoUrl'];

          if (photoUrl != null && photoUrl.isNotEmpty) {
            try {
              // Kiểm tra xem là Link Online hay Base64
              if (photoUrl.startsWith('http')) {
                imageProvider = NetworkImage(photoUrl);
              } else {
                // Giải mã Base64
                imageProvider = MemoryImage(base64Decode(photoUrl));
              }
            } catch (e) {
              print("Lỗi ảnh avatar: $e");
            }
          }
        }

        // 2. ƯU TIÊN SỐ 2: Nếu Firestore chưa có/lỗi -> Dùng ảnh Google (Auth)
        if (imageProvider == null && user.photoURL != null) {
          imageProvider = NetworkImage(user.photoURL!);
        }

        // 3. Hiển thị
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageProvider,
          // Nếu không có ảnh nào thì hiện Icon mặt người
          child: (imageProvider == null)
              ? Icon(Icons.person, size: radius, color: Colors.grey)
              : null,
        );
      },
    );
  }
}