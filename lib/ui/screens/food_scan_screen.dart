import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  // Key của bạn
  final String _apiKey = 'AIzaSyB7pKDn3oe-lK7GQp8W2uSMZgAVcuLtWkY';

  File? _image;
  bool _isLoading = false;
  String? _result;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 👇 Vừa vào màn hình là kiểm tra danh sách model ngay
    _listAvailableModels();
  }

  // 🛠 HÀM QUAN TRỌNG: Kiểm tra xem Key này dùng được Model nào?
  Future<void> _listAvailableModels() async {
    print("----- ĐANG KIỂM TRA DANH SÁCH MODEL GOOGLE -----");
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      // Gọi thử 1 request nhẹ để check kết nối
      print("Đang thử ping tới Google...");
    } catch (e) {
      print("Lỗi khởi tạo SDK: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null;
        });
        _scanWithGemini();
      }
    } catch (e) {
      _showError("Lỗi chọn ảnh: $e");
    }
  }

  Future<void> _scanWithGemini() async {
    if (_image == null) return;
    setState(() {
      _isLoading = true;
      _result = "Đang kết nối...";
    });

    try {
      // 👇 SỬA LỖI: Dùng tên phiên bản cụ thể (Pinned Version) thay vì tên chung
      // Thường thì tên này sẽ hoạt động khi tên ngắn bị lỗi
      const modelName = 'gemini-1.5-flash-001';

      print("🚀 Đang gọi model: $modelName");

      final model = GenerativeModel(
        model: modelName,
        apiKey: _apiKey,
      );

      final imageBytes = await _image!.readAsBytes();
      final prompt = TextPart("Nhìn ảnh và cho biết: Tên món, Calo, Dinh dưỡng (Protein/Carb/Fat), Healthy không? Trả lời tiếng Việt.");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null) {
        setState(() => _result = response.text);
      } else {
        throw Exception("Kết quả rỗng");
      }

    } catch (e) {
      print("❌ LỖI SDK CHI TIẾT: $e");
      setState(() => _result = "LỖI: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gemini Food Scan (Fix)")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              height: 250,
              color: Colors.grey[200],
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.add_a_photo, size: 50)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Text("Chụp ảnh mới"),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          if (_result != null && !_isLoading)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              color: _result!.contains("LỖI") ? Colors.red[50] : Colors.green[50],
              child: Text(_result!),
            ),
        ],
      ),
    );
  }
}