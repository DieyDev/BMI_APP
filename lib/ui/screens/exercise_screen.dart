import 'package:flutter/material.dart';
import '../../services/theme_service.dart'; // Import ThemeService
import 'exercise_detail_screen.dart'; // <--- QUAN TRỌNG: Import màn hình đếm giờ

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Setup Animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy trạng thái Dark Mode
    final bool isDark = ThemeService.instance.isDarkMode;

    // Màu sắc theo theme
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color appBarBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color unselectedColor = isDark ? Colors.grey : Colors.grey.shade600;
    Color indicatorColor = isDark ? const Color(0xFFBB86FC) : const Color(0xFF667eea);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
            "Bài tập đề xuất",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF667eea),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: indicatorColor,
          unselectedLabelColor: unselectedColor,
          indicatorColor: indicatorColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Giảm cân", icon: Icon(Icons.directions_run)),
            Tab(text: "Tăng cơ", icon: Icon(Icons.fitness_center)),
            Tab(text: "Yoga", icon: Icon(Icons.self_improvement)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildExerciseList(getWeightLossExercises(), isDark, const Color(0xFFFF512F)),
            _buildExerciseList(getMuscleGainExercises(), isDark, const Color(0xFF667eea)),
            _buildExerciseList(getYogaExercises(), isDark, const Color(0xFF00B09B)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(List<Map<String, String>> exercises, bool isDark, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final item = exercises[index];

        // Animation trượt từng item
        return SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.1 * index, 1.0, curve: Curves.easeOut),
          )),
          child: _buildExerciseCard(item, isDark, accentColor),
        );
      },
    );
  }

  Widget _buildExerciseCard(Map<String, String> item, bool isDark, Color accentColor) {
    Color cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    Color titleColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // --- SỬA ĐỔI QUAN TRỌNG Ở ĐÂY: CHUYỂN MÀN HÌNH ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseDetailScreen(exercise: item),
              ),
            );
          },
          // --------------------------------------------------
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                      Icons.play_arrow_rounded,
                      color: accentColor,
                      size: 32
                  ),
                ),
                const SizedBox(width: 16),

                // Nội dung text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc']!,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Tags: Thời gian & Calo
                      Row(
                        children: [
                          _buildTag(Icons.timer_outlined, item['time']!, Colors.orange, isDark),
                          const SizedBox(width: 12),
                          _buildTag(Icons.local_fire_department_rounded, item['cal']!, Colors.red, isDark),
                        ],
                      )
                    ],
                  ),
                ),

                // Mũi tên
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dữ liệu giả lập ---
  List<Map<String, String>> getWeightLossExercises() => [
    {"name": "Chạy tại chỗ", "desc": "Nâng cao đùi, duy trì nhịp thở đều.", "time": "15 phút", "cal": "150 kcal"},
    {"name": "Nhảy dây", "desc": "Tốt cho tim mạch và đốt mỡ toàn thân.", "time": "10 phút", "cal": "120 kcal"},
    {"name": "Burpees", "desc": "Bài tập cường độ cao đốt mỡ thừa.", "time": "5 phút", "cal": "80 kcal"},
    {"name": "Jumping Jacks", "desc": "Bật nhảy dang tay chân nhịp nhàng.", "time": "10 phút", "cal": "100 kcal"},
    {"name": "Leo núi tại chỗ", "desc": "Mô phỏng động tác leo núi.", "time": "8 phút", "cal": "90 kcal"},
  ];

  List<Map<String, String>> getMuscleGainExercises() => [
    {"name": "Hít đất (Push-ups)", "desc": "Phát triển cơ ngực và tay sau.", "time": "3 hiệp x 12", "cal": "50 kcal"},
    {"name": "Squat", "desc": "Tăng cơ mông và đùi.", "time": "3 hiệp x 15", "cal": "60 kcal"},
    {"name": "Plank", "desc": "Siết cơ bụng, giữ thẳng lưng.", "time": "60 giây", "cal": "10 kcal"},
    {"name": "Lunges", "desc": "Chùn chân, tốt cho đùi trước.", "time": "3 hiệp x 10", "cal": "45 kcal"},
    {"name": "Gập bụng", "desc": "Tác động vào cơ bụng trên.", "time": "3 hiệp x 20", "cal": "30 kcal"},
  ];

  List<Map<String, String>> getYogaExercises() => [
    {"name": "Tư thế Chiến binh", "desc": "Tăng sức mạnh cho chân và hông.", "time": "5 phút", "cal": "20 kcal"},
    {"name": "Tư thế Rắn hổ mang", "desc": "Giãn cơ lưng và cột sống.", "time": "3 phút", "cal": "15 kcal"},
    {"name": "Thiền định", "desc": "Thư giãn tâm trí và giảm stress.", "time": "10 phút", "cal": "5 kcal"},
    {"name": "Chào mặt trời", "desc": "Chuỗi động tác khởi động toàn thân.", "time": "7 phút", "cal": "35 kcal"},
    {"name": "Tư thế Cái cây", "desc": "Cải thiện thăng bằng và tập trung.", "time": "4 phút", "cal": "10 kcal"},
  ];
}