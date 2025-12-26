import 'dart:convert'; // Thư viện để mã hóa ảnh
import 'dart:io';
import 'dart:typed_data'; // Xử lý dữ liệu ảnh
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _gender = "Male";
  String? _currentPhotoData; // Lưu chuỗi Base64 hoặc URL
  File? _selectedImage;
  bool _isLoading = false;

  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService = FirestoreService(uid: user.uid);
      _nameController.text = user.displayName ?? "";
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firestoreService.getUserProfile();
      if (data != null) {
        setState(() {
          _nameController.text = data['displayName'] ?? "";
          _ageController.text = data['age']?.toString() ?? "";
          _heightController.text = data['height']?.toString() ?? "";
          _weightController.text = data['weight']?.toString() ?? "";
          _gender = data['gender'] ?? "Male";
          if (data['photoUrl'] != null) _currentPhotoData = data['photoUrl'];
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // QUAN TRỌNG: imageQuality: 20 để nén ảnh thật nhỏ, tránh lỗi Firestore
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Hàm chuyển ảnh thành chuỗi Base64
  Future<String?> _imageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Lỗi mã hóa ảnh: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      String? photoString;

      // Nếu có chọn ảnh mới -> Chuyển thành Base64
      if (_selectedImage != null) {
        photoString = await _imageToBase64(_selectedImage!);
        _currentPhotoData = photoString;
      }

      await user?.updateDisplayName(_nameController.text.trim());
      // Lưu ý: Không updatePhotoURL của Auth vì nó giới hạn độ dài chuỗi
      await user?.reload();

      // Lưu chuỗi ảnh vào Firestore
      await _firestoreService.updateUserProfile(
        displayName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        height: double.tryParse(_heightController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0,
        gender: _gender,
        photoUrl: photoString, // Lưu chuỗi Base64 vào đây
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu thành công!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị ảnh (Xử lý cả File, Base64 và URL)
  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    if (_currentPhotoData != null && _currentPhotoData!.isNotEmpty) {
      try {
        // Nếu là Base64 (không chứa http)
        if (!_currentPhotoData!.startsWith('http')) {
          return MemoryImage(base64Decode(_currentPhotoData!));
        }
        // Nếu là URL cũ
        return NetworkImage(_currentPhotoData!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _getImageProvider(),
                      child: (_getImageProvider() == null)
                          ? Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "U",
                        style: const TextStyle(fontSize: 40, color: Color(0xFF667eea), fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFF667eea), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text("Chạm để đổi ảnh", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // ... (Các ô nhập liệu giữ nguyên như cũ) ...
              TextFormField(
                controller: _nameController,
                decoration: _inputDecor("Họ và tên", Icons.person),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: _inputDecor("Tuổi", Icons.cake))),
                const SizedBox(width: 16),
                Expanded(child: DropdownButtonFormField<String>(value: _gender, decoration: _inputDecor("Giới tính", Icons.transgender), items: const [DropdownMenuItem(value: "Male", child: Text("Nam")), DropdownMenuItem(value: "Female", child: Text("Nữ"))], onChanged: (val) => setState(() => _gender = val!))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(controller: _heightController, keyboardType: TextInputType.number, decoration: _inputDecor("Chiều cao (cm)", Icons.height))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _weightController, keyboardType: TextInputType.number, decoration: _inputDecor("Cân nặng (kg)", Icons.monitor_weight))),
              ]),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
    );
  }
}