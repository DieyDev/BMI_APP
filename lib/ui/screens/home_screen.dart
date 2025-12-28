import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../models/bmi_record.dart';

import '../../services/firestore_service.dart';

import '../../widgets/side_menu.dart';

import '../../services/theme_service.dart'; // 1. MỚI THÊM: Import ThemeService

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

  String? _photoData;


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

// Khởi tạo các giá trị màu mặc định để tránh lỗi LateInitializationError

    _primaryColor = const Color(0xFFFF9966);

    _secondaryColor = const Color(0xFFFF5E62);

    _gradientColors = [_primaryColor, _secondaryColor];

    _timeGreeting = "";

    _timeIcon = Icons.access_time;


// Gọi hàm setup màu

    _setupTheme();

    _statusColor = _primaryColor;


    String uid = FirebaseAuth.instance.currentUser!.uid;

    _firestoreService = FirestoreService(uid: uid);


    _loadUserData();


// --- Animation Setup ---

    _animationController = AnimationController(

      duration: const Duration(milliseconds: 1500),

      vsync: this,

    );


    _pulseController = AnimationController(

      duration: const Duration(milliseconds: 1800),

      vsync: this,

    );


    _shimmerController = AnimationController(

      duration: const Duration(milliseconds: 2000),

      vsync: this,

    )
      ..repeat(reverse: true);


    _floatingController = AnimationController(

      duration: const Duration(milliseconds: 3000),

      vsync: this,

    )
      ..repeat(reverse: true);


    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(

      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),

    );


    _slideAnimation = Tween<Offset>(

      begin: const Offset(0, 0.3),

      end: Offset.zero,

    ).animate(

      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),

    );


    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(

      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),

    );


    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(

      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),

    );


    _floatingAnimation = Tween<double>(begin: -5, end: 5).animate(

      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),

    );


    _animationController.forward();
  }


// 2. MỚI THÊM: Lắng nghe thay đổi theme từ hệ thống (khi bấm nút switch)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _setupTheme(); // Cập nhật lại màu khi theme đổi

  }


// 3. ĐÃ SỬA: Hàm xử lý màu (Ưu tiên Dark Mode -> sau đó mới tới giờ giấc)

  void _setupTheme() {
// Kiểm tra xem đang bật chế độ tối hay không

    bool isDark = ThemeService.instance.isDarkMode;


    if (isDark) {
// --- CẤU HÌNH MÀU CHO CHẾ ĐỘ TỐI ---

      _primaryColor =
      const Color(0xFFBB86FC); // Tím sáng (nổi bật trên nền đen)

      _secondaryColor = const Color(0xFF3700B3); // Tím đậm

      _gradientColors =
      [const Color(0xFF2C2C2C), const Color(0xFF1F1F1F)]; // Gradient xám đen

      _timeGreeting = "Chế độ tối";

      _timeIcon = Icons.nights_stay_rounded;


// Nếu chưa tính BMI thì set màu mặc định, nếu tính rồi thì giữ nguyên màu trạng thái

      if (_bmiValue == 0) _statusColor = _primaryColor;
    } else {
// --- CẤU HÌNH MÀU THEO GIỜ (NHƯ CŨ) ---

      final hour = DateTime
          .now()
          .hour;


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


// Cập nhật lại giao diện

    if (mounted) setState(() {});
  }


  Future<void> _loadUserData() async {
    final data = await _firestoreService.getUserProfile();

    final user = FirebaseAuth.instance.currentUser;


    if (mounted) {
      setState(() {
        if (data != null) {
          if (data['height'] != null && data['height'] > 0) {
            _heightController.text = data['height'].toString();
          }

          if (data['weight'] != null && data['weight'] > 0) {
            _weightController.text = data['weight'].toString();
          }

          if (data['age'] != null && data['age'] > 0) {
            final int savedAge = data['age'];

            _selectedDate = DateTime(DateTime
                .now()
                .year - savedAge, 1, 1);
          }

          if (data['gender'] != null) _isMale = data['gender'] == 'Male';


          _displayName =
              data['displayName'] ?? user?.displayName ?? "Người dùng";

          _photoData = data['photoUrl'];
        } else {
          _displayName = user?.displayName ?? "Người dùng";
        }
      });


      if (_heightController.text.isNotEmpty &&
          _weightController.text.isNotEmpty) {
        _calculateBMI();
      }
    }
  }


  ImageProvider? _getAvatarImage() {
    if (_photoData != null && _photoData!.isNotEmpty) {
      try {
        if (!_photoData!.startsWith('http')) {
          return MemoryImage(base64Decode(_photoData!));
        }

        return NetworkImage(_photoData!);
      } catch (_) {}
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user?.photoURL != null) return NetworkImage(user!.photoURL!);

    return null;
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

            const Icon(
                Icons.warning_amber_rounded, color: Colors.white, size: 28),

            const SizedBox(width: 12),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text("Dữ liệu không hợp lệ",
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14)),

                  Text(message, style: const TextStyle(fontSize: 13)),

                ],

              ),

            ),

          ],

        ),

        backgroundColor: const Color(0xFFE74C3C),
        // Màu đỏ lỗi

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        margin: const EdgeInsets.all(16),

        duration: const Duration(seconds: 4),

      ),

    );
  }


// --- LOGIC BẪY LỖI (VALIDATION) ---

  bool _validateInputs({bool showError = true}) {
// 1. Bẫy lỗi Ngày sinh

    if (_selectedDate == null) {
      if (showError) _showErrorSnackBar(
          "Vui lòng chọn ngày sinh để chúng tôi tính tuổi chính xác.");

      return false;
    }


    int age = _calculatedAge;

    if (age < 2) {
      if (showError) _showErrorSnackBar(
          "Ứng dụng chỉ hỗ trợ tính BMI cho người trên 2 tuổi.");

      return false;
    }

    if (age > 120) {
      if (showError) _showErrorSnackBar(
          "Số tuổi không hợp lý (> 120). Vui lòng kiểm tra năm sinh.");

      return false;
    }


// 2. Bẫy lỗi Chiều cao

    String hText = _heightController.text.trim();

    if (hText.isEmpty) {
      if (showError) _showErrorSnackBar("Bạn chưa nhập chiều cao.");

      return false;
    }


// Hỗ trợ dấu phẩy

    double? height = double.tryParse(hText.replaceAll(',', '.'));

    if (height == null) {
      if (showError) _showErrorSnackBar("Chiều cao phải là số (Ví dụ: 170).");

      return false;
    }

    if (height < 50 || height > 275) {
      if (showError) _showErrorSnackBar(
          "Chiều cao không thực tế (Phải từ 50cm - 275cm).");

      return false;
    }


// 3. Bẫy lỗi Cân nặng

    String wText = _weightController.text.trim();

    if (wText.isEmpty) {
      if (showError) _showErrorSnackBar("Bạn chưa nhập cân nặng.");

      return false;
    }


// Hỗ trợ dấu phẩy

    double? weight = double.tryParse(wText.replaceAll(',', '.'));

    if (weight == null) {
      if (showError) _showErrorSnackBar("Cân nặng phải là số (Ví dụ: 65.5).");

      return false;
    }

    if (weight < 3 || weight > 600) {
      if (showError) _showErrorSnackBar(
          "Cân nặng không thực tế (Phải từ 3kg - 600kg).");

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

      _idealWeightRange =
      "${minIdeal.toStringAsFixed(1)}-${maxIdeal.toStringAsFixed(1)} kg";


      if (bmi < 16.0) {
        _bmiStatus = "Gầy độ III";

        _statusColor = const Color(0xFF3498DB);

        _healthAdvice = "⚠️ Cần tăng cân ngay. Tham khảo bác sĩ dinh dưỡng.";

        _weightDifference =
        "Cần tăng ${(minIdeal - weight).toStringAsFixed(1)} kg";
      } else if (bmi < 17.0) {
        _bmiStatus = "Gầy độ II";

        _statusColor = const Color(0xFF5DADE2);

        _healthAdvice = "Cân nặng thấp. Bổ sung dinh dưỡng và protein.";

        _weightDifference =
        "Cần tăng ${(minIdeal - weight).toStringAsFixed(1)} kg";
      } else if (bmi < 18.5) {
        _bmiStatus = "Gầy độ I";

        _statusColor = const Color(0xFF85C1E9);

        _healthAdvice = "Hơi thiếu cân. Tăng cường dinh dưỡng cân bằng.";

        _weightDifference =
        "Cần tăng ${(minIdeal - weight).toStringAsFixed(1)} kg";
      } else if (bmi < 25.0) {
        _bmiStatus = "Bình thường ✨";

        _statusColor = const Color(0xFF2ECC71);

        _healthAdvice =
        "🎉 Tuyệt vời! Duy trì lối sống lành mạnh và vận động đều đặn.";

        _weightDifference = "";
      } else if (bmi < 30.0) {
        _bmiStatus = "Thừa cân";

        _statusColor = const Color(0xFFF39C12);

        _healthAdvice = "Nên giảm cân nhẹ. Tăng vận động và ăn uống điều độ.";

        _weightDifference =
        "Nên giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
      } else if (bmi < 35.0) {
        _bmiStatus = "Béo phì độ I";

        _statusColor = const Color(0xFFE67E22);

        _healthAdvice = "⚠️ Cần giảm cân. Tham khảo chuyên gia dinh dưỡng.";

        _weightDifference =
        "Nên giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
      } else if (bmi < 40.0) {
        _bmiStatus = "Béo phì độ II";

        _statusColor = const Color(0xFFE74C3C);

        _healthAdvice = "⚠️ Cần giảm cân nghiêm túc. Gặp bác sĩ chuyên khoa.";

        _weightDifference =
        "Nên giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
      } else {
        _bmiStatus = "Béo phì độ III";

        _statusColor = const Color(0xFFC0392B);

        _healthAdvice = "🚨 Nghiêm trọng. Can thiệp y tế ngay lập tức.";

        _weightDifference =
        "Nên giảm ${(weight - maxIdeal).toStringAsFixed(1)} kg";
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


// Cập nhật Profile

      await _firestoreService.updateUserProfile(

        displayName: _displayName,

        gender: _isMale ? "Male" : "Female",

        height: h,

        weight: w,

        age: _calculatedAge,

        photoUrl: _photoData,

      );


// Lưu vào Lịch sử

      BmiRecord newRecord = BmiRecord(

        height: h,

        weight: w,

        bmi: _bmiValue,

        date: DateTime.now(),

      );

      await _firestoreService.addRecord(newRecord);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Row(

              children: const [

                Icon(Icons.check_circle_rounded, color: Colors.white),

                SizedBox(width: 12),

                Text("✓ Đã lưu kết quả thành công!", style: TextStyle(
                    fontWeight: FontWeight.w600)),

              ],

            ),

            backgroundColor: const Color(0xFF2ECC71),

            behavior: SnackBarBehavior.floating,

            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),

            margin: const EdgeInsets.all(16),

          ),

        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("Lỗi hệ thống: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
// 4. MỚI: Lấy màu nền từ Theme hệ thống (Main.dart) thay vì cứng

    return Scaffold(

      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,

      appBar: _buildAppBar(),

      drawer: SideMenu(

        onProfileUpdated: () {
          _loadUserData();

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Row(

                children: const [

                  Icon(Icons.check_circle_rounded, color: Colors.white),

                  SizedBox(width: 12),

                  Text("Dữ liệu đã được cập nhật",
                      style: TextStyle(fontWeight: FontWeight.w600)),

                ],

              ),

              backgroundColor: const Color(0xFF2ECC71),

              behavior: SnackBarBehavior.floating,

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),

              margin: const EdgeInsets.all(16),

            ),

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

              _buildWelcomeHeader(),

              const SizedBox(height: 24),

              _buildInputCard(),

              const SizedBox(height: 20),

              _buildCalculateButton(),

              if (_bmiValue > 0) ...[

                const SizedBox(height: 24),

                _buildModernGauge(),

                const SizedBox(height: 20),

                _buildResultCard(),

                const SizedBox(height: 16),

                _buildHealthAdviceCard(),

                const SizedBox(height: 16),

                _buildIdealWeightCard(),

                const SizedBox(height: 20),

                _buildBMIReferenceCard(),

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

// AppBar sẽ tự ăn theo Theme trong Main.dart, không cần set màu ở đây

      leading: Builder(

        builder: (context) =>
            IconButton(

              icon: Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  gradient: LinearGradient(colors: _gradientColors),
                  // Màu theo theme/giờ

                  borderRadius: BorderRadius.circular(12),

                  boxShadow: [

                    BoxShadow(

                      color: _primaryColor.withOpacity(0.4),

                      blurRadius: 10,

                      offset: const Offset(0, 4),

                    ),

                  ],

                ),

                child: const Icon(
                    Icons.menu_rounded, color: Colors.white, size: 20),

              ),

              onPressed: () => Scaffold.of(context).openDrawer(),

            ),

      ),

      title: const Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            "BMI Calculator",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 18,

              letterSpacing: -0.5,

            ),

          ),

          Text(

            "WHO Standard",

            style: TextStyle(

              fontSize: 11,

              fontWeight: FontWeight.w500,

            ),

          ),

        ],

      ),

      actions: [

        _buildActionButton(

          Icons.history_rounded,

          _primaryColor, // Màu theo theme/giờ

              () =>
              Navigator.push(

                context,

                MaterialPageRoute(builder: (_) => const HistoryScreen()),

              ),

        ),

        _buildActionButton(

          Icons.save_rounded,

          const Color(0xFF2ECC71),

          _isSaving ? null : _saveToFirebase,

          isLoading: _isSaving,

        ),

        const SizedBox(width: 8),

      ],

    );
  }


  Widget _buildActionButton(IconData icon, Color color, VoidCallback? onPressed,
      {bool isLoading = false}) {
    return Padding(

      padding: const EdgeInsets.only(right: 4),

      child: IconButton(

        icon: isLoading

            ? SizedBox(

          width: 20,

          height: 20,

          child: CircularProgressIndicator(

            strokeWidth: 2.5,

            color: color,

          ),

        )

            : Container(

          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(

            color: color.withOpacity(0.1),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(

              color: color.withOpacity(0.2),

              width: 1,

            ),

          ),

          child: Icon(icon, color: color, size: 20),

        ),

        onPressed: onPressed,

      ),

    );
  }


  Widget _buildWelcomeHeader() {
    return SlideTransition(

      position: _slideAnimation,

      child: ScaleTransition(

        scale: _scaleAnimation,

        child: Container(

          margin: const EdgeInsets.symmetric(horizontal: 20),

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            gradient: LinearGradient(

              colors: _gradientColors, // Màu theo theme/giờ

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

            ),

            borderRadius: BorderRadius.circular(24),

            boxShadow: [

              BoxShadow(

                color: _primaryColor.withOpacity(0.5),

                blurRadius: 25,

                offset: const Offset(0, 12),

              ),

            ],

          ),

          child: Row(

            children: [

              Container(

                width: 60,

                height: 60,

                decoration: BoxDecoration(

                  color: Colors.white.withOpacity(0.25),

                  shape: BoxShape.circle,

                  border: Border.all(

                    color: Colors.white.withOpacity(0.5),

                    width: 3,

                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withOpacity(0.1),

                      blurRadius: 10,

                      offset: const Offset(0, 4),

                    ),

                  ],

                ),

                child: ClipOval(

                  child: _getAvatarImage() != null

                      ? Image(image: _getAvatarImage()!, fit: BoxFit.cover)

                      : const Icon(
                      Icons.person_rounded, color: Colors.white, size: 32),

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Text(

                          _timeGreeting,

                          style: TextStyle(

                            color: Colors.white.withOpacity(0.9),

                            fontSize: 14,

                            fontWeight: FontWeight.w500,

                          ),

                        ),

                        const SizedBox(width: 6),

                        Icon(_timeIcon, size: 16, color: Colors.white),

                      ],

                    ),

                    const SizedBox(height: 4),

                    Text(

                      _displayName.isNotEmpty ? _displayName : 'Người dùng',

                      style: const TextStyle(

                        color: Colors.white,

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                        letterSpacing: -0.5,

                      ),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                    ),

                  ],

                ),

              ),

              Container(

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: Colors.white.withOpacity(0.2),

                  borderRadius: BorderRadius.circular(14),

                ),

                child: const Icon(

                  Icons.favorite_rounded,

                  color: Colors.white,

                  size: 28,

                ),

              ),

            ],

          ),

        ),

      ),

    );
  }


  Widget _buildInputCard() {
// Màu nền Card dựa trên Theme

    Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;

    Color iconColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.white : _primaryColor;

    Color textColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.white : const Color(0xFF2C3E50);


    return AnimatedBuilder(

      animation: _floatingAnimation,

      builder: (context, child) {
        return Transform.translate(

          offset: Offset(0, _floatingAnimation.value),

          child: SlideTransition(

            position: Tween<Offset>(

              begin: const Offset(0, 0.2),

              end: Offset.zero,

            ).animate(

              CurvedAnimation(

                parent: _animationController,

                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),

              ),

            ),

            child: Container(

              margin: const EdgeInsets.symmetric(horizontal: 20),

              padding: const EdgeInsets.all(28),

              decoration: BoxDecoration(

                color: cardColor, // Màu nền theo Theme

                borderRadius: BorderRadius.circular(24),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.1),

                    blurRadius: 30,

                    offset: const Offset(0, 8),

                  ),

                ],

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Container(

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(

                          gradient: LinearGradient(

                            colors: [

                              _primaryColor.withOpacity(0.2),

                              _secondaryColor.withOpacity(0.2),

                            ],

                          ),

                          borderRadius: BorderRadius.circular(12),

                        ),

                        child: Icon(

                          Icons.person_outline_rounded,

                          color: iconColor,

                          size: 22,

                        ),

                      ),

                      const SizedBox(width: 12),

                      Text(

                        "Thông tin cơ bản",

                        style: TextStyle(

                          fontSize: 20,

                          fontWeight: FontWeight.bold,

                          color: textColor, // Màu chữ theo Theme

                          letterSpacing: -0.5,

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 24),

                  _buildGenderSelection(),

                  const SizedBox(height: 20),

                  Row(

                    children: [

                      Expanded(

                        child: _buildModernInputField(

                          "Chiều cao",

                          _heightController,

                          "cm",

                          Icons.height_rounded,

                          _primaryColor,

                        ),

                      ),

                      const SizedBox(width: 16),

                      Expanded(

                        child: _buildModernInputField(

                          "Cân nặng",

                          _weightController,

                          "kg",

                          Icons.monitor_weight_outlined,

                          const Color(0xFF2ECC71),

                        ),

                      ),

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


  Widget _buildDatePickerField() {
    bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    Color textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    Color hintColor = isDark ? Colors.grey : Colors.grey.shade400;

    Color boxColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF39C12)
        .withOpacity(0.05);


    return GestureDetector(

      onTap: () async {
        final DateTime? picked = await showDatePicker(

          context: context,

          initialDate: _selectedDate ?? DateTime(2000),

          firstDate: DateTime(1900),

          lastDate: DateTime.now(),

          builder: (context, child) {
            return Theme(

              data: Theme.of(context).copyWith(

                colorScheme: ColorScheme.light(

                  primary: _primaryColor,

                  onPrimary: Colors.white,

                  onSurface: const Color(0xFF2C3E50),

                ),

              ),

              child: child!,

            );
          },

        );

        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Icon(
                  Icons.cake_rounded, size: 18, color: const Color(0xFFF39C12)),

              const SizedBox(width: 6),

              Text(

                "Ngày sinh",

                style: TextStyle(

                  fontSize: 14,

                  fontWeight: FontWeight.w600,

                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,

                ),

              ),

            ],

          ),

          const SizedBox(height: 10),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

            decoration: BoxDecoration(

              color: boxColor,

              borderRadius: BorderRadius.circular(14),

              border: Border.all(

                color: const Color(0xFFF39C12).withOpacity(0.2),

                width: 1.5,

              ),

            ),

            child: Row(

              children: [

                Expanded(

                  child: Text(

                    _selectedDate == null

                        ? "Chọn ngày sinh"

                        : "Ngày ${_selectedDate!.day}/${_selectedDate!
                        .month}/${_selectedDate!
                        .year} • ${_calculatedAge} tuổi",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      color: _selectedDate == null ? hintColor : textColor,

                    ),

                  ),

                ),

                const Icon(
                    Icons.calendar_month_rounded, color: Color(0xFFF39C12)),

              ],

            ),

          ),

        ],

      ),

    );
  }


  Widget _buildGenderSelection() {
    bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    Color unselectedColor = isDark ? const Color(0xFF1F1F1F) : const Color(
        0xFFF8F9FA);

    Color unselectedIconColor = isDark ? Colors.grey : Colors.grey.shade400;


    return Row(

      children: [

        Expanded(

          child: GestureDetector(

            onTap: () => setState(() => _isMale = true),

            child: AnimatedContainer(

              duration: const Duration(milliseconds: 300),

              curve: Curves.easeInOut,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(

                gradient: _isMale

                    ? LinearGradient(colors: _gradientColors)

                    : null,

                color: _isMale ? null : unselectedColor,

                borderRadius: BorderRadius.circular(16),

                border: Border.all(

                  color: _isMale ? Colors.transparent : Colors.grey.shade300,

                  width: 2,

                ),

                boxShadow: _isMale

                    ? [

                  BoxShadow(

                    color: _primaryColor.withOpacity(0.4),

                    blurRadius: 15,

                    offset: const Offset(0, 6),

                  ),

                ]

                    : null,

              ),

              child: Column(

                children: [

                  Icon(

                    Icons.male_rounded,

                    size: 42,

                    color: _isMale ? Colors.white : unselectedIconColor,

                  ),

                  const SizedBox(height: 8),

                  Text(

                    "Nam",

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                      color: _isMale ? Colors.white : Colors.grey.shade600,

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

        const SizedBox(width: 16),

        Expanded(

          child: GestureDetector(

            onTap: () => setState(() => _isMale = false),

            child: AnimatedContainer(

              duration: const Duration(milliseconds: 300),

              curve: Curves.easeInOut,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(

                gradient: !_isMale

                    ? const LinearGradient(

                  colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],

                )

                    : null,

                color: !_isMale ? null : unselectedColor,

                borderRadius: BorderRadius.circular(16),

                border: Border.all(

                  color: !_isMale ? Colors.transparent : Colors.grey.shade300,

                  width: 2,

                ),

                boxShadow: !_isMale

                    ? [

                  BoxShadow(

                    color: const Color(0xFFFF6B9D).withOpacity(0.4),

                    blurRadius: 15,

                    offset: const Offset(0, 6),

                  ),

                ]

                    : null,

              ),

              child: Column(

                children: [

                  Icon(

                    Icons.female_rounded,

                    size: 42,

                    color: !_isMale ? Colors.white : unselectedIconColor,

                  ),

                  const SizedBox(height: 8),

                  Text(

                    "Nữ",

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                      color: !_isMale ? Colors.white : Colors.grey.shade600,

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ],

    );
  }


  Widget _buildModernInputField(String label,

      TextEditingController controller,

      String unit,

      IconData icon,

      Color color,

      {bool isIntegerOnly = false}) {
    bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    Color textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    Color labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    Color boxColor = isDark ? const Color(0xFF1F1F1F) : color.withOpacity(0.05);


    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            Icon(icon, size: 18, color: color),

            const SizedBox(width: 6),

            Text(

              label,

              style: TextStyle(

                fontSize: 14,

                fontWeight: FontWeight.w600,

                color: labelColor,

              ),

            ),

          ],

        ),

        const SizedBox(height: 10),

        Container(

          decoration: BoxDecoration(

            color: boxColor,

            borderRadius: BorderRadius.circular(14),

            border: Border.all(

              color: color.withOpacity(0.2),

              width: 1.5,

            ),

          ),

          child: TextField(

            controller: controller,

            keyboardType: TextInputType.numberWithOptions(
                decimal: !isIntegerOnly),

            inputFormatters: isIntegerOnly

                ? [FilteringTextInputFormatter.digitsOnly]

                : [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: textColor,

            ),

            decoration: InputDecoration(

              suffixText: unit,

              suffixStyle: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.w600,

                color: color,

              ),

              border: InputBorder.none,

              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),

              hintText: "0",

              hintStyle: TextStyle(color: Colors.grey.shade400),

            ),

          ),

        ),

      ],

    );
  }


  Widget _buildCalculateButton() {
    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 20),

        width: double.infinity,

        height: 60,

        child: ElevatedButton(

          onPressed: () {
            FocusScope.of(context).unfocus();

            _calculateBMI();
          },

          style: ElevatedButton.styleFrom(

            backgroundColor: Colors.transparent,

            shadowColor: Colors.transparent,

            padding: EdgeInsets.zero,

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(18),

            ),

          ),

          child: Ink(

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: _gradientColors, // Màu theo theme/giờ

                begin: Alignment.centerLeft,

                end: Alignment.centerRight,

              ),

              borderRadius: BorderRadius.circular(18),

              boxShadow: [

                BoxShadow(

                  color: _primaryColor.withOpacity(0.5),

                  blurRadius: 20,

                  offset: const Offset(0, 10),

                ),

              ],

            ),

            child: Container(

              alignment: Alignment.center,

              child: const Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Icon(Icons.calculate_rounded, color: Colors.white, size: 24),

                  SizedBox(width: 12),

                  Text(

                    "TÍNH BMI",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 1.2,

                      color: Colors.white,

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );
  }


  Widget _buildModernGauge() {
// Màu nền Card theo theme

    Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;


    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: ScaleTransition(

        scale: _pulseAnimation,

        child: Container(

          margin: const EdgeInsets.symmetric(horizontal: 20),

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color: cardColor,

            borderRadius: BorderRadius.circular(24),

            boxShadow: [

              BoxShadow(

                color: _statusColor.withOpacity(0.3),

                blurRadius: 30,

                offset: const Offset(0, 10),

              ),

            ],

          ),

          child: Column(

            children: [

              SizedBox(

                height: 220,

                child: SfRadialGauge(

                  axes: <RadialAxis>[

                    RadialAxis(

                      minimum: 10,

                      maximum: 45,

                      startAngle: 180,

                      endAngle: 0,

                      showLabels: false,

                      showTicks: false,

                      axisLineStyle: const AxisLineStyle(

                        thickness: 0.15,

                        cornerStyle: CornerStyle.bothCurve,

                        thicknessUnit: GaugeSizeUnit.factor,

                      ),

                      pointers: <GaugePointer>[

                        NeedlePointer(

                          value: _bmiValue,

                          needleLength: 0.7,

                          enableAnimation: true,

                          animationDuration: 1500,

                          animationType: AnimationType.easeOutBack,

                          needleStartWidth: 1.5,

                          needleEndWidth: 6,

                          needleColor: _statusColor,

                          knobStyle: KnobStyle(

                            knobRadius: 0.08,

                            color: Colors.white,

                            borderColor: _statusColor,

                            borderWidth: 0.04,

                          ),

                        ),

                      ],

                      ranges: <GaugeRange>[

                        GaugeRange(

                          startValue: 10,

                          endValue: 18.5,

                          color: const Color(0xFF3498DB),

                          startWidth: 20,

                          endWidth: 20,

                        ),

                        GaugeRange(

                          startValue: 18.5,

                          endValue: 25,

                          color: const Color(0xFF2ECC71),

                          startWidth: 20,

                          endWidth: 20,

                        ),

                        GaugeRange(

                          startValue: 25,

                          endValue: 30,

                          color: const Color(0xFFF39C12),

                          startWidth: 20,

                          endWidth: 20,

                        ),

                        GaugeRange(

                          startValue: 30,

                          endValue: 45,

                          color: const Color(0xFFE74C3C),

                          startWidth: 20,

                          endWidth: 20,

                        ),

                      ],

                      annotations: <GaugeAnnotation>[

                        GaugeAnnotation(

                          widget: Column(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Text(

                                _bmiValue.toStringAsFixed(1),

                                style: TextStyle(

                                  fontSize: 48,

                                  fontWeight: FontWeight.bold,

                                  color: _statusColor,

                                  height: 1,

                                ),

                              ),

                              const SizedBox(height: 4),

                              Text(

                                "BMI",

                                style: const TextStyle(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: Colors.grey,

                                  letterSpacing: 2,

                                ),

                              ),

                            ],

                          ),

                          angle: 90,

                          positionFactor: 0.75,

                        ),

                      ],

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 16),

              Container(

                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),

                decoration: BoxDecoration(

                  color: _statusColor.withOpacity(0.1),

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(

                    color: _statusColor.withOpacity(0.3),

                    width: 2,

                  ),

                ),

                child: Text(

                  _bmiStatus,

                  style: TextStyle(

                    fontSize: 20,

                    fontWeight: FontWeight.bold,

                    color: _statusColor,

                    letterSpacing: 0.5,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );
  }


  Widget _buildResultCard() {
    Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;

    Color textColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey
        .shade700;


    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: cardColor,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(

            color: _statusColor.withOpacity(0.3),

            width: 2,

          ),

        ),

        child: Column(

          children: [

            Row(

              children: [

                Container(

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color: _statusColor.withOpacity(0.2),

                    borderRadius: BorderRadius.circular(12),

                  ),

                  child: Icon(

                    Icons.analytics_rounded,

                    color: _statusColor,

                    size: 24,

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        "Chỉ số BMI của bạn",

                        style: TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w600,

                          color: textColor,

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        _bmiValue.toStringAsFixed(2),

                        style: TextStyle(

                          fontSize: 24,

                          fontWeight: FontWeight.bold,

                          color: _statusColor,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            if (_weightDifference.isNotEmpty) ...[

              const SizedBox(height: 16),

              Container(

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(

                  color: Theme
                      .of(context)
                      .brightness == Brightness.dark ? Colors.black26 : Colors
                      .grey.shade50,

                  borderRadius: BorderRadius.circular(14),

                ),

                child: Row(

                  children: [

                    Icon(

                      _bmiValue < 18.5 ? Icons.arrow_upward_rounded : Icons
                          .arrow_downward_rounded,

                      color: _statusColor,

                      size: 20,

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      child: Text(

                        _weightDifference,

                        style: TextStyle(

                          fontSize: 15,

                          fontWeight: FontWeight.w600,

                          color: _statusColor,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ],

        ),

      ),

    );
  }


  Widget _buildHealthAdviceCard() {
    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.7, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          gradient: LinearGradient(

            colors: _gradientColors, // Màu theo theme/giờ

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

          ),

          borderRadius: BorderRadius.circular(20),

          boxShadow: [

            BoxShadow(

              color: _primaryColor.withOpacity(0.4),

              blurRadius: 20,

              offset: const Offset(0, 8),

            ),

          ],

        ),

        child: Row(

          children: [

            Container(

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(

                color: Colors.white.withOpacity(0.2),

                borderRadius: BorderRadius.circular(12),

              ),

              child: const Icon(

                Icons.lightbulb_rounded,

                color: Colors.white,

                size: 28,

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    "Lời khuyên sức khỏe",

                    style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.w600,

                      color: Colors.white.withOpacity(0.9),

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    _healthAdvice,

                    style: const TextStyle(

                      fontSize: 15,

                      fontWeight: FontWeight.w500,

                      color: Colors.white,

                      height: 1.4,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );
  }


  Widget _buildIdealWeightCard() {
    Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;

    Color textColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey
        .shade700;


    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.8, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: cardColor,

          borderRadius: BorderRadius.circular(20),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(0.08),

              blurRadius: 20,

              offset: const Offset(0, 6),

            ),

          ],

        ),

        child: Row(

          children: [

            Container(

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(

                gradient: LinearGradient(

                  colors: [

                    const Color(0xFF2ECC71).withOpacity(0.2),

                    const Color(0xFF27AE60).withOpacity(0.2),

                  ],

                ),

                borderRadius: BorderRadius.circular(12),

              ),

              child: const Icon(

                Icons.favorite_rounded,

                color: Color(0xFF2ECC71),

                size: 28,

              ),

            ),

            const SizedBox(width: 16),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    "Cân nặng lý tưởng",

                    style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.w600,

                      color: textColor,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    _idealWeightRange,

                    style: const TextStyle(

                      fontSize: 20,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFF2ECC71),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );
  }


  Widget _buildBMIReferenceCard() {
    Color cardColor = Theme
        .of(context)
        .cardTheme
        .color ?? Colors.white;

    Color titleColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.white : const Color(0xFF2C3E50);


    return SlideTransition(

      position: Tween<Offset>(

        begin: const Offset(0, 0.3),

        end: Offset.zero,

      ).animate(

        CurvedAnimation(

          parent: _animationController,

          curve: const Interval(0.9, 1.0, curve: Curves.easeOut),

        ),

      ),

      child: Container(

        margin: const EdgeInsets.symmetric(horizontal: 20),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: cardColor,

          borderRadius: BorderRadius.circular(20),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withOpacity(0.08),

              blurRadius: 20,

              offset: const Offset(0, 6),

            ),

          ],

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Container(

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(

                    gradient: LinearGradient(

                      colors: [

                        _primaryColor.withOpacity(0.2),

                        _secondaryColor.withOpacity(0.2),

                      ],

                    ),

                    borderRadius: BorderRadius.circular(12),

                  ),

                  child: Icon(

                    Icons.info_outline_rounded,

                    color: _primaryColor, // Màu theo theme/giờ

                    size: 22,

                  ),

                ),

                const SizedBox(width: 12),

                Text(

                  "Bảng phân loại BMI (WHO)",

                  style: TextStyle(

                    fontSize: 16,

                    fontWeight: FontWeight.bold,

                    color: titleColor,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 16),

            _buildBMIReferenceRow(
                "Gầy độ III", "< 16", const Color(0xFF3498DB)),

            _buildBMIReferenceRow(
                "Gầy độ II", "16 - 17", const Color(0xFF5DADE2)),

            _buildBMIReferenceRow(
                "Gầy độ I", "17 - 18.5", const Color(0xFF85C1E9)),

            _buildBMIReferenceRow(
                "Bình thường ✨", "18.5 - 25", const Color(0xFF2ECC71)),

            _buildBMIReferenceRow(
                "Thừa cân", "25 - 30", const Color(0xFFF39C12)),

            _buildBMIReferenceRow(
                "Béo phì độ I", "30 - 35", const Color(0xFFE67E22)),

            _buildBMIReferenceRow(
                "Béo phì độ II", "35 - 40", const Color(0xFFE74C3C)),

            _buildBMIReferenceRow(
                "Béo phì độ III", "> 40", const Color(0xFFC0392B)),

          ],

        ),

      ),

    );
  }


  Widget _buildBMIReferenceRow(String label, String range, Color color) {
    Color textColor = Theme
        .of(context)
        .brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey
        .shade700;


    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(

        children: [

          Container(

            width: 12,

            height: 12,

            decoration: BoxDecoration(

              color: color,

              shape: BoxShape.circle,

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              label,

              style: TextStyle(

                fontSize: 14,

                fontWeight: FontWeight.w600,

                color: textColor,

              ),

            ),

          ),

          Text(

            range,

            style: TextStyle(

              fontSize: 14,

              fontWeight: FontWeight.bold,

              color: color,

            ),

          ),

        ],

      ),

    );
  }
}