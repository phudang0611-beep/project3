import 'category_model.dart';

class ExpenseTransaction {
  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? imagePath;
  final String? rawOcrText;
  final DateTime createdAt;

  ExpenseTransaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as String,
      merchant: map['merchant'] as String? ?? 'Unknown Merchant',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ExpenseCategory.fromString(map['category'] as String?),
      imagePath: map['imagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ExpenseTransaction copyWith({
    String? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
