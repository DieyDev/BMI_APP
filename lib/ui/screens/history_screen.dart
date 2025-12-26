// File: lib/ui/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bmi_record.dart';
import '../../services/firestore_service.dart';
import '../../services/theme_service.dart'; // Import ThemeService

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _sortBy = 'date'; // 'date' hoặc 'bmi'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final FirestoreService firestoreService = FirestoreService(uid: uid);

    // Kiểm tra chế độ tối
    final bool isDark = ThemeService.instance.isDarkMode;

    return Scaffold(
      // Lấy màu nền từ Theme hệ thống
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<List<BmiRecord>>(
        stream: firestoreService.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), isDark);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          final records = _sortRecords(snapshot.data!);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildStatsHeader(records, isDark),
                _buildSortButtons(isDark),
                Expanded(
                  child: ListView.builder(
                    itemCount: records.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(
                        context,
                        records[index],
                        index,
                        firestoreService,
                        isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      // Màu nền AppBar tự động theo Theme (đã cấu hình ở main.dart)
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF1F1F1F)] // Gradient tối
                    : [const Color(0xFF667eea), const Color(0xFF764ba2)], // Gradient sáng
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lịch sử đo",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          Text(
            "Theo dõi tiến trình",
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE74C3C).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFE74C3C), size: 20),
          ),
          onPressed: () => _showDeleteAllDialog(context, isDark),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsHeader(List<BmiRecord> records, bool isDark) {
    final avgBmi = records.isEmpty
        ? 0.0
        : records.map((r) => r.bmi).reduce((a, b) => a + b) / records.length;
    final trend = records.length >= 2
        ? records[0].bmi - records[1].bmi
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1F1F1F)]
              : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Tổng số lần đo",
                  records.length.toString(),
                  Icons.format_list_numbered_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  "BMI trung bình",
                  avgBmi.toStringAsFixed(1),
                  Icons.analytics_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      trend > 0 ? Icons.trending_up_rounded :
                      trend < 0 ? Icons.trending_down_rounded :
                      Icons.trending_flat_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Xu hướng gần đây",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  trend == 0 ? "Ổn định" :
                  "${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSortButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSortButton(
              'Mới nhất',
              'date',
              Icons.calendar_today_rounded,
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSortButton(
              'Theo BMI',
              'bmi',
              Icons.sort_rounded,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String sortType, IconData icon, bool isDark) {
    final isSelected = _sortBy == sortType;
    Color activeColor = isDark ? const Color(0xFFBB86FC) : const Color(0xFF667eea);

    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.grey.shade600),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
      BuildContext context,
      BmiRecord record,
      int index,
      FirestoreService firestoreService,
      bool isDark,
      ) {
    final color = _getColor(record.bmi);
    final status = _getStatus(record.bmi);

    Color cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.grey.shade800;
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(record.id ?? index.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.delete_rounded, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                "Xóa",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteDialog(context, isDark);
        },
        onDismissed: (direction) {
          if (record.id != null) {
            firestoreService.deleteRecord(record.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Đã xóa bản ghi", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                backgroundColor: const Color(0xFFE74C3C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black12 : color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showDetailDialog(context, record, isDark),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            record.bmi.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "BMI",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.scale_rounded, size: 14, color: subTextColor),
                              const SizedBox(width: 6),
                              Text(
                                "${record.weight} kg",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.height_rounded, size: 14, color: subTextColor),
                              const SizedBox(width: 6),
                              Text(
                                "${record.height} cm",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: subTextColor),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(record.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF1F1F1F)]
                    : [const Color(0xFF667eea), const Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Đang tải dữ liệu...",
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Đã xảy ra lỗi",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white10, Colors.white10]
                    : [const Color(0xFF667eea).withOpacity(0.1), const Color(0xFF764ba2).withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 80,
              color: isDark ? Colors.white70 : const Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Chưa có lịch sử đo",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "Hãy tính toán BMI và lưu kết quả để theo dõi tiến trình của bạn",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              "Quay lại tính BMI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 5,
              shadowColor: const Color(0xFF667eea).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<BmiRecord> _sortRecords(List<BmiRecord> records) {
    final sorted = List<BmiRecord>.from(records);
    if (_sortBy == 'bmi') {
      sorted.sort((a, b) => b.bmi.compareTo(a.bmi));
    } else {
      sorted.sort((a, b) => b.date.compareTo(a.date));
    }
    return sorted;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Hôm nay, ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays == 1) {
      return "Hôm qua, ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} ngày trước";
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  Color _getColor(double bmi) {
    if (bmi < 16.0) return const Color(0xFF3498DB);
    if (bmi < 17.0) return const Color(0xFF5DADE2);
    if (bmi < 18.5) return const Color(0xFF85C1E9);
    if (bmi < 25.0) return const Color(0xFF2ECC71);
    if (bmi < 30.0) return const Color(0xFFF39C12);
    if (bmi < 35.0) return const Color(0xFFE67E22);
    if (bmi < 40.0) return const Color(0xFFE74C3C);
    return const Color(0xFFC0392B);
  }

  String _getStatus(double bmi) {
    if (bmi < 16.0) return "Gầy độ III";
    if (bmi < 17.0) return "Gầy độ II";
    if (bmi < 18.5) return "Gầy độ I";
    if (bmi < 25.0) return "Bình thường";
    if (bmi < 30.0) return "Thừa cân";
    if (bmi < 35.0) return "Béo phì độ I";
    if (bmi < 40.0) return "Béo phì độ II";
    return "Béo phì độ III";
  }

  Future<bool?> _showDeleteDialog(BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFF39C12), size: 28),
            SizedBox(width: 12),
            Text("Xác nhận xóa"),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa bản ghi này không?",
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Hủy",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Xóa",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFE74C3C), size: 28),
            SizedBox(width: 12),
            Text("Xóa tất cả?"),
          ],
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa toàn bộ lịch sử đo không? Hành động này không thể hoàn tác.",
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete all
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text("Chức năng đang phát triển"),
                    ],
                  ),
                  backgroundColor: const Color(0xFF667eea),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Xóa tất cả",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, BmiRecord record, bool isDark) {
    final color = _getColor(record.bmi);
    final status = _getStatus(record.bmi);
    Color dialogBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    Color textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius:20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      record.bmi.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "BMI",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                  Icons.scale_rounded,
                  "Cân nặng",
                  "${record.weight} kg",
                  color,
                  textColor
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  Icons.height_rounded,
                  "Chiều cao",
                  "${record.height} cm",
                  color,
                  textColor
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  Icons.calendar_today_rounded,
                  "Ngày đo",
                  DateFormat('dd/MM/yyyy').format(record.date),
                  color,
                  textColor
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  Icons.access_time_rounded,
                  "Thời gian",
                  DateFormat('HH:mm:ss').format(record.date),
                  color,
                  textColor
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 5,
                  shadowColor: color.withOpacity(0.5),
                ),
                child: const Text(
                  "Đóng",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}