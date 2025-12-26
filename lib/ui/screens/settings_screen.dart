import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Cần thêm vào pubspec.yaml
import '../../services/firestore_service.dart';
import '../../services/theme_service.dart'; // Import service giao diện

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Biến trạng thái
  bool _isNotificationEnabled = true;
  bool _isLoading = false; // Để hiện vòng xoay khi xóa dữ liệu

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  // Load cài đặt thông báo từ bộ nhớ máy
  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      });
    }
  }

  // Xử lý bật/tắt thông báo
  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isNotificationEnabled = value);
    await prefs.setBool('isNotificationEnabled', value);
  }

  // Xử lý xóa dữ liệu lịch sử
  Future<void> _handleDeleteHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa toàn bộ lịch sử đo BMI? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final service = FirestoreService(uid: uid);
          await service.deleteAllRecords();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã xóa toàn bộ dữ liệu!"), backgroundColor: Colors.green),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái Dark Mode từ Service
    final isDark = ThemeService.instance.isDarkMode;
    final textColor = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      // Bỏ màu nền cứng để ăn theo Theme global
      appBar: AppBar(
        title: const Text("Cài đặt"), // Bỏ style cứng để ăn theo Theme
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text("Giao diện & Tiện ích", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              _buildSettingsCard(
                context,
                children: [
                  SwitchListTile(
                    title: const Text("Chế độ tối", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text("Giao diện nền tối bảo vệ mắt"),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Icon(Icons.dark_mode_rounded, color: isDark ? Colors.purple.shade200 : Colors.purple.shade400),
                    ),
                    value: isDark, // Dùng giá trị từ Service
                    activeColor: const Color(0xFF667eea),
                    onChanged: (val) {
                      // Gọi Service để đổi màu toàn App
                      ThemeService.instance.toggleTheme(val);
                      setState(() {}); // Rebuild để cập nhật UI
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Thông báo nhắc nhở", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: const Text("Nhắc nhở nhập chỉ số BMI mỗi tuần"),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.orange),
                    ),
                    value: _isNotificationEnabled,
                    activeColor: const Color(0xFF667eea),
                    onChanged: _toggleNotification,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text("Thông tin & Hỗ trợ", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              _buildSettingsCard(
                context,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.info_outline_rounded, color: Colors.blue),
                    ),
                    title: const Text("Phiên bản ứng dụng"),
                    trailing: Text("1.0.0", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.privacy_tip_outlined, color: Colors.green),
                    ),
                    title: const Text("Chính sách bảo mật"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang mở trình duyệt...")));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSettingsCard(
                  context,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      ),
                      title: const Text("Xóa dữ liệu lịch sử", style: TextStyle(color: Colors.red)),
                      onTap: _handleDeleteHistory, // Gọi hàm xóa thật
                    ),
                  ]
              )
            ],
          ),

          // Hiệu ứng Loading khi đang xóa
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // Cập nhật hàm này để Card đổi màu theo Theme
  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white, // Màu nền động
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}