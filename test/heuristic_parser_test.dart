import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker_01/models/category_model.dart';
import 'package:ocr_expense_tracker_01/services/heuristic_parser.dart';

void main() {
  group('HeuristicParser Tests', () {
    test('Parses Vietnamese standard receipt with "150,000 VND"', () {
      const receiptText = '''
        HÓA ĐƠN BÁN LẺ
        HIGHLANDS COFFEE
        ĐC: 123 Nguyen Hue, Q1, TP.HCM
        Ngày: 15/10/2026 14:30
        1. Phin Sữa Đá: 45,000
        2. Freeze Trà Xanh: 65,000
        3. Bánh Mì Thịt Nướng: 40,000
        TỔNG CỘNG: 150,000 VND
        Tiền khách đưa: 200,000
        Tiền thối: 50,000
        Cảm ơn quý khách!
      ''';

      final result = HeuristicParser.parse(receiptText);
      expect(result.amount, equals(150000.0));
      expect(result.merchant, equals('HIGHLANDS COFFEE'));
      expect(result.date, equals(DateTime(2026, 10, 15)));
      expect(result.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('Parses receipt with "150.000 đ" and dot separated numbers', () {
      const receiptText = '''
        PHIẾU THANH TOÁN
        NHÀ SÁCH PHƯƠNG NAM
        Thời gian: 08-10-2026
        Sách Giáo Trình: 150.000 đ
        THÀNH TIỀN: 150.000 đ
      ''';

      final result = HeuristicParser.parse(receiptText);
      expect(result.amount, equals(150000.0));
      expect(result.merchant, equals('NHÀ SÁCH PHƯƠNG NAM'));
      expect(result.date, equals(DateTime(2026, 10, 8)));
      expect(result.suggestedCategory, equals(ExpenseCategory.study));
    });

    test('Parses Travel category from Grab receipt', () {
      const receiptText = '''
        GRAB VIETNAM
        Dich vu: GrabBike
        Date: 20/09/2026
        TOTAL: 35,000 VND
      ''';

      final result = HeuristicParser.parse(receiptText);
      expect(result.amount, equals(35000.0));
      expect(result.suggestedCategory, equals(ExpenseCategory.travel));
    });

    test('Parses Gear category from FPT Shop receipt', () {
      const receiptText = '''
        FPT SHOP
        Phu kien chuot ban phim
        Tong tien: 250.000
        Ngay: 01/11/2026
      ''';

      final result = HeuristicParser.parse(receiptText);
      expect(result.amount, equals(250000.0));
      expect(result.suggestedCategory, equals(ExpenseCategory.gear));
    });
  });
}
