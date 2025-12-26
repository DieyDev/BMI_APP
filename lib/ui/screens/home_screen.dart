// File: lib/ui/screens/home_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../models/bmi_record.dart';
import '../../services/firestore_service.dart';
import '../../widgets/side_menu.dart';
import '../../services/theme_service.dart';
import '../../widgets/user_avatar.dart'; // ✅ QUAN TRỌNG: Import Widget UserAvatar

import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  DateTime? _selectedDate;
  bool _isMale = true;
  double _bmiValue = 0.0;
  String _bmiStatus = "Chưa tính toán";
  Color _statusColor = Colors.grey;
  bool _isSaving = false;
  String _idealWeightRange = "--";
  String _healthAdvice = "Nhập thông tin để nhận tư vấn";
  String _weightDifference = "";
  String _displayName = "";

  // ⚠️ Đã xóa biến _photoData vì UserAvatar tự xử lý

  // --- VARIABLES CHO THEME ---
  late Color _primaryColor;
  late Color _secondaryColor;
  late List<Color> _gradientColors;
  late String _timeGreeting;
  late IconData _timeIcon;

  late FirestoreService _firestoreService;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  int get _calculatedAge {
    if (_selectedDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    // Khởi tạo màu mặc định
    _primaryColor = const Color(0xFFFF9966);
    _secondaryColor = const Color(0xFFFF5E62);
    _gradientColors = [_primaryColor, _secondaryColor];
    _timeGreeting = "";
    _timeIcon = Icons.access_time;
    _statusColor = _primaryColor;

    // Setup Theme
    _setupTheme();

    // Firebase Init
    String uid = FirebaseAuth.instance.currentUser!.uid;
    _firestoreService = FirestoreService(uid: uid);
    _loadUserData();

    // --- Animation Setup ---
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _shimmerController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)..repeat(reverse: true);
    _floatingController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this)..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _floatingAnimation = Tween<double>(begin: -5, end: 5).animate(CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupTheme();
  }

  void _setupTheme() {
    bool isDark = ThemeService.instance.isDarkMode;
    if (isDark) {
      _primaryColor = const Color(0xFFBB86FC);
      _secondaryColor = const Color(0xFF3700B3);
      _gradientColors = [const Color(0xFF2C2C2C), const Color(0xFF1F1F1F)];
      _timeGreeting = "Chế độ tối";
      _timeIcon = Icons.nights_stay_rounded;
      if (_bmiValue == 0) _statusColor = _primaryColor;
    } else {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        _primaryColor = const Color(0xFFFF9966);
        _secondaryColor = const Color(0xFFFF5E62);
        _timeGreeting = "Chào buổi sáng";
        _timeIcon = Icons.wb_sunny_rounded;
      } else if (hour >= 12 && hour < 18) {
        _primaryColor = const Color(0xFF56CCF2);
        _secondaryColor = const Color(0xFF2F80ED);
        _timeGreeting = "Chào buổi chiều";
        _timeIcon = Icons.wb_cloudy_rounded;
      } else {
        _primaryColor = const Color(0xFF667eea);
        _secondaryColor = const Color(0xFF764ba2);
        _timeGreeting = "Chào buổi tối";
        _timeIcon = Icons.nights_stay_rounded;
      }
      _gradientColors = [_primaryColor, _secondaryColor];
      if (_bmiValue == 0) _statusColor = _primaryColor;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadUserData() async {
    final data = await _firestoreService.getUserProfile();
    final user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        if (data != null) {
          if (data['height'] != null && data['height'] > 0) _heightController.text = data['height'].toString();
          if (data['weight'] != null && data['weight'] > 0) _weightController.text = data['weight'].toString();
          if (data['age'] != null && data['age'] > 0) {
            final int savedAge = data['age'];
            _selectedDate = DateTime(DateTime.now().year - savedAge, 1, 1);
          }
          if (data['gender'] != null) _isMale = data['gender'] == 'Male';
          _displayName = data['displayName'] ?? user?.displayName ?? "Người dùng";
          // ✅ KHÔNG load photoData ở đây để tránh xung đột
        } else {
          _displayName = user?.displayName ?? "Người dùng";
        }
      });
      if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty) {
        _calculateBMI();
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _validateInputs({bool showError = true}) {
    if (_selectedDate == null) {
      if (showError) _showErrorSnackBar("Vui lòng chọn ngày sinh.");
      return false;
    }
    if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
      if (showError) _showErrorSnackBar("Vui lòng nhập chiều cao và cân nặng.");
      return false;
    }
    return true;
  }

  void _calculateBMI() {
    if (!_validateInputs(showError: true)) {
      setState(() {
        _bmiValue = 0.0;
        _bmiStatus = "Chưa tính toán";
        _statusColor = _primaryColor;
        _idealWeightRange = "--";
        _healthAdvice = "Nhập thông tin hợp lệ để nhận tư vấn";
        _weightDifference = "";
      });
      return;
    }

    double height = double.parse(_heightController.text.replaceAll(',', '.'));
    double weight = double.parse(_weightController.text.replaceAll(',', '.'));
    double heightM = height / 100;
    double bmi = weight / (heightM * heightM);
    double minIdeal = 18.5 * heightM * heightM;
    double maxIdeal = 24.9 * heightM * heightM;

    setState(() {
      _bmiValue = bmi;
      _idealWeightRange = "${minIdeal.toStringAsFixed(1)}-${maxIdeal.toStringAsFixed(1)} kg";

      if (bmi < 18.5) {
        _bmiStatus = "Thiếu cân"; _statusColor = const Color(0xFF5DADE2);
        _healthAdvice = "Cần bổ sung dinh dưỡng.";
        _weightDifference = "Tăng ${(minIdeal - weight).toStringAsFixed(1)} kg";
      } else if (bmi < 25) {
        _bmiStatus = "Bình thường"; _statusColor = const Color(0xFF2ECC71);
        _healthAdvice = "Duy trì lối sống lành mạnh.";
        _weightDifference = "";
      } else if (bmi < 30) {
        _bmiStatus = "Thừa cân"; _statusColor = const Color(0xFFF39C12);
        _healthAdvice = "Nên vận động nhiều hơn.";
        _weightDifference = "Giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
      } else {
        _bmiStatus = "Béo phì"; _statusColor = const Color(0xFFE74C3C);
        _healthAdvice = "Cần chế độ ăn kiêng và tập luyện.";
        _weightDifference = "Giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
      }
    });

    _pulseController.reset();
    _pulseController.forward();
  }

  void _saveToFirebase() async {
    FocusScope.of(context).unfocus();
    if (!_validateInputs()) return;
    _calculateBMI();

    setState(() => _isSaving = true);

    try {
      double h = double.parse(_heightController.text.replaceAll(',', '.'));
      double w = double.parse(_weightController.text.replaceAll(',', '.'));

      // Cập nhật Profile (Chỉ số liệu, không cập nhật ảnh ở đây)
      await _firestoreService.updateUserProfile(
        displayName: _displayName,
        gender: _isMale ? "Male" : "Female",
        height: h,
        weight: w,
        age: _calculatedAge,
      );

      BmiRecord newRecord = BmiRecord(height: h, weight: w, bmi: _bmiValue, date: DateTime.now());
      await _firestoreService.addRecord(newRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã lưu thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      drawer: SideMenu(
        onProfileUpdated: () {
          _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Dữ liệu đã cập nhật"), backgroundColor: Colors.green)
          );
        },
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildWelcomeHeader(), // ✅ Header đã sửa
              const SizedBox(height: 24),
              _buildInputCard(), // ✅ Đã khôi phục đầy đủ
              const SizedBox(height: 20),
              _buildCalculateButton(),
              if (_bmiValue > 0) ...[
                const SizedBox(height: 24),
                _buildModernGauge(), // ✅ Đã khôi phục
                const SizedBox(height: 20),
                _buildResultCard(), // ✅ Đã khôi phục
                const SizedBox(height: 16),
                _buildHealthAdviceCard(), // ✅ Đã khôi phục
                const SizedBox(height: 16),
                _buildIdealWeightCard(), // ✅ Đã khôi phục
                const SizedBox(height: 20),
                _buildBMIReferenceCard(), // ✅ Đã khôi phục
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Builder(
        builder: (c) => IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : _primaryColor),
          onPressed: () => Scaffold.of(c).openDrawer(),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BMI Calculator", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text("WHO Standard", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : _primaryColor),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Colors.green),
          onPressed: _isSaving ? null : _saveToFirebase,
        ),
      ],
    );
  }

  // ✅ HÀM NÀY ĐÃ ĐƯỢC SỬA ĐỂ DÙNG USER AVATAR
  Widget _buildWelcomeHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.5), blurRadius: 25, offset: const Offset(0, 12))],
          ),
          child: Row(
            children: [
              // 👇 Dùng UserAvatar ở đây để đồng bộ ảnh
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: const UserAvatar(radius: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_timeGreeting, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        Icon(_timeIcon, size: 16, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 👇 PHỤC HỒI ĐẦY ĐỦ CÁC WIDGET INPUT VÀ HIỂN THỊ 👇

  Widget _buildInputCard() {
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Thông tin cơ bản", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildGenderSelection(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildModernInputField("Chiều cao", _heightController, "cm", Icons.height, _primaryColor)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildModernInputField("Cân nặng", _weightController, "kg", Icons.monitor_weight, const Color(0xFF2ECC71))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerField(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderSelection() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color unselectedColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF8F9FA);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isMale = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _isMale ? LinearGradient(colors: _gradientColors) : null,
                color: _isMale ? null : unselectedColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isMale ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Column(children: [
                Icon(Icons.male, size: 42, color: _isMale ? Colors.white : Colors.grey),
                const SizedBox(height: 8),
                Text("Nam", style: TextStyle(color: _isMale ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isMale = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: !_isMale ? const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)]) : null,
                color: !_isMale ? null : unselectedColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: !_isMale ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Column(children: [
                Icon(Icons.female, size: 42, color: !_isMale ? Colors.white : Colors.grey),
                const SizedBox(height: 8),
                Text("Nữ", style: TextStyle(color: !_isMale ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInputField(String label, TextEditingController controller, String unit, IconData icon, Color color) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color boxColor = isDark ? const Color(0xFF1F1F1F) : color.withOpacity(0.05);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 6), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              suffixText: unit, suffixStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
              border: InputBorder.none, contentPadding: const EdgeInsets.all(16), hintText: "0",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color boxColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF39C12).withOpacity(0.05);
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context, initialDate: _selectedDate ?? DateTime(2000),
          firstDate: DateTime(1900), lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.cake, size: 18, color: Color(0xFFF39C12)), SizedBox(width: 6), Text("Ngày sinh", style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.2))),
            child: Row(
              children: [
                Expanded(child: Text(_selectedDate == null ? "Chọn ngày sinh" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • $_calculatedAge tuổi")),
                const Icon(Icons.calendar_month, color: Color(0xFFF39C12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity, height: 60,
        child: ElevatedButton(
          onPressed: () { FocusScope.of(context).unfocus(); _calculateBMI(); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: Ink(
            decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))]),
            child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calculate, color: Colors.white), SizedBox(width: 12), Text("TÍNH BMI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])),
          ),
        ),
      ),
    );
  }

  Widget _buildModernGauge() {
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _statusColor.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))]),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: SfRadialGauge(axes: <RadialAxis>[
                RadialAxis(
                  minimum: 10, maximum: 45, startAngle: 180, endAngle: 0, showLabels: false, showTicks: false,
                  pointers: <GaugePointer>[NeedlePointer(value: _bmiValue, needleColor: _statusColor, knobStyle: KnobStyle(color: Colors.white, borderColor: _statusColor))],
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 10, endValue: 18.5, color: Colors.blue),
                    GaugeRange(startValue: 18.5, endValue: 25, color: Colors.green),
                    GaugeRange(startValue: 25, endValue: 30, color: Colors.orange),
                    GaugeRange(startValue: 30, endValue: 45, color: Colors.red),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(widget: Column(mainAxisSize: MainAxisSize.min, children: [Text(_bmiValue.toStringAsFixed(1), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _statusColor)), const Text("BMI")]), angle: 90, positionFactor: 0.75),
                  ],
                ),
              ]),
            ),
            Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Text(_bmiStatus, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _statusColor))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: _statusColor.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.analytics, color: _statusColor), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Chỉ số BMI"), Text(_bmiValue.toStringAsFixed(2), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _statusColor))]))
          ]),
          if (_weightDifference.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: [Icon(Icons.arrow_forward, color: _statusColor), const SizedBox(width: 10), Text(_weightDifference, style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor))]),
          ]
        ],
      ),
    );
  }

  Widget _buildHealthAdviceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const Icon(Icons.lightbulb, color: Colors.white, size: 28), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Lời khuyên", style: TextStyle(color: Colors.white.withOpacity(0.9))), Text(_healthAdvice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
      ]),
    );
  }

  Widget _buildIdealWeightCard() {
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: Row(children: [
        const Icon(Icons.favorite, color: Colors.green, size: 28), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Cân nặng lý tưởng"), Text(_idealWeightRange, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))])),
      ]),
    );
  }

  Widget _buildBMIReferenceCard() {
    Color cardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Bảng phân loại BMI (WHO)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _row("Gầy", "< 18.5", Colors.blue),
        _row("Bình thường", "18.5 - 25", Colors.green),
        _row("Thừa cân", "25 - 30", Colors.orange),
        _row("Béo phì", "> 30", Colors.red),
      ]),
    );
  }

  Widget _row(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(range, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}