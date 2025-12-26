import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, String> exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  // Timer variables
  Timer? _timer;
  int _start = 0;
  int _totalTime = 0;
  bool _isTimerRunning = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _parseTime();

    // Animation cho vòng tròn progress
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalTime > 0 ? _totalTime : 1),
    );
  }

  // Hàm xử lý chuỗi thời gian giả lập từ data (VD: "15 phút" -> 900s, "60 giây" -> 60s)
  void _parseTime() {
    String timeStr = widget.exercise['time']!;
    if (timeStr.contains("phút")) {
      _totalTime = int.parse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) * 60;
    } else if (timeStr.contains("giây")) {
      _totalTime = int.parse(timeStr.replaceAll(RegExp(r'[^0-9]'), ''));
    } else {
      _totalTime = 60; // Mặc định 60s nếu là "hiệp"
    }
    _start = _totalTime;
  }

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    _controller.forward();
    setState(() => _isTimerRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer!.cancel();
          _isTimerRunning = false;
          _isCompleted = true;
        });
        _showCompletionDialog();
      } else {
        setState(() => _start--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _controller.stop();
    setState(() => _isTimerRunning = false);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 50),
            SizedBox(height: 10),
            Text("Chúc mừng!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Bạn đã hoàn thành bài tập ${widget.exercise['name']} và đốt cháy ${widget.exercise['cal']}.",
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay về màn hình danh sách
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Tuyệt vời", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeService.instance.isDarkMode;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Tên & Mô tả
            Text(
              widget.exercise['name']!,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.exercise['desc']!,
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 50),

            // 2. Vòng tròn đếm giờ
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 1 - (_start / _totalTime), // Progress ngược
                    strokeWidth: 15,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$_start",
                      style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const Text("Giây", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 50),

            // 3. Nút điều khiển
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isCompleted)
                  ElevatedButton.icon(
                    onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_isTimerRunning ? "Tạm dừng" : "Bắt đầu"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}