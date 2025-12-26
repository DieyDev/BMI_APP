// File: lib/models/bmi_record.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BmiRecord {
  final String? id; // ID của document trong Firestore
  final double height; // Chiều cao (cm)
  final double weight; // Cân nặng (kg)
  final double bmi; // Chỉ số BMI
  final DateTime date; // Ngày đo

  BmiRecord({
    this.id,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.date,
  });

  // Chuyển từ Object sang Map (để lưu vào Firestore)
  Map<String, dynamic> toMap() {
    return {
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'date': Timestamp.fromDate(date),
    };
  }

  // Chuyển từ Firestore Document sang BmiRecord Object
  factory BmiRecord.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BmiRecord(
      id: doc.id,
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      bmi: (data['bmi'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // Chuyển từ Map sang BmiRecord (dùng cho local storage)
  factory BmiRecord.fromMap(Map<String, dynamic> map) {
    return BmiRecord(
      id: map['id'],
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date']),
    );
  }

  // Copy with (để update một số field)
  BmiRecord copyWith({
    String? id,
    double? height,
    double? weight,
    double? bmi,
    DateTime? date,
  }) {
    return BmiRecord(
      id: id ?? this.id,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      date: date ?? this.date,
    );
  }

  // Phân loại BMI
  String get status {
    if (bmi < 18.5) return 'Nhẹ cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  // Màu theo trạng thái
  String get statusColor {
    if (bmi < 18.5) return '#2196F3'; // Blue
    if (bmi < 25) return '#4CAF50'; // Green
    if (bmi < 30) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  // Lời khuyên
  String get advice {
    if (bmi < 18.5) {
      return 'Bạn nên tăng cân bằng cách ăn đủ chất dinh dưỡng và tập luyện phù hợp.';
    } else if (bmi < 25) {
      return 'Chỉ số BMI của bạn ở mức lý tưởng. Hãy duy trì lối sống lành mạnh!';
    } else if (bmi < 30) {
      return 'Bạn nên giảm cân nhẹ bằng chế độ ăn cân bằng và tăng cường vận động.';
    } else {
      return 'Bạn nên tham khảo ý kiến bác sĩ để có kế hoạch giảm cân phù hợp.';
    }
  }

  // Format hiển thị ngày giờ
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  String toString() {
    return 'BmiRecord(id: $id, height: $height, weight: $weight, bmi: $bmi, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BmiRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}