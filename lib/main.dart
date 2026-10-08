import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/category_model.dart';
import 'models/transaction_model.dart';
import 'services/database_helper.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed initial demo transactions if first run
  await _seedInitialDataIfEmpty();

  runApp(const OcrExpenseTrackerApp());
}

Future<void> _seedInitialDataIfEmpty() async {
  final dbHelper = DatabaseHelper.instance;
  final existing = await dbHelper.getAllTransactions();
  if (existing.isEmpty) {
    final now = DateTime.now();
    final sampleExpenses = [
      ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: 'Highlands Coffee',
        amount: 55000,
        date: now.subtract(const Duration(days: 0)),
        category: ExpenseCategory.food,
        rawOcrText: 'HIGHLANDS COFFEE\nPHIN SUA DA SIZE L\nTONG CONG: 55,000 VND\nNGAY: ${now.day}/${now.month}/${now.year}',
      ),
      ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: 'Nhà Sách Phương Nam',
        amount: 145000,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.study,
        rawOcrText: 'NHA SACH PHUONG NAM\nGIAO TRINH FLUTTER & DART\nTHANH TIEN: 145.000 đ',
      ),
      ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: 'Grab Bike',
        amount: 32000,
        date: now.subtract(const Duration(days: 2)),
        category: ExpenseCategory.travel,
        rawOcrText: 'GRAB VIETNAM\nCHUYEN DI DIEN THOAI\nTOTAL: 32,000 VND',
      ),
      ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: 'FPT Shop - Type C Cable',
        amount: 180000,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.gear,
        rawOcrText: 'FPT SHOP\nCAP SAC NHANH ANKER TYPE C\nTỔNG TIỀN: 180,000 đ',
      ),
      ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: 'CGV Cinemas',
        amount: 110000,
        date: now.subtract(const Duration(days: 4)),
        category: ExpenseCategory.entertainment,
        rawOcrText: 'CGV CINEMAS VIETNAM\nVE XEM PHIM 2D\nTONG CONG: 110.000 VND',
      ),
    ];

    for (final tx in sampleExpenses) {
      await dbHelper.insertTransaction(tx);
    }
  }
}

class OcrExpenseTrackerApp extends StatelessWidget {
  const OcrExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF06B6D4),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
