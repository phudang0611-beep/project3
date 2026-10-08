import '../models/category_model.dart';

class ParsedReceiptResult {
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final ExpenseCategory suggestedCategory;
  final List<String> rawLines;

  ParsedReceiptResult({
    this.amount,
    this.date,
    this.merchant,
    this.suggestedCategory = ExpenseCategory.food,
    required this.rawLines,
  });
}

class HeuristicParser {
  // Common Vietnamese and English total keywords
  static final List<String> _totalKeywords = [
    'tong cong',
    'tổng cộng',
    'tong tien',
    'tổng tiền',
    'thanh tien',
    'thành tiền',
    'tien thanh toan',
    'tiền thanh toán',
    'phai thanh toan',
    'phải thanh toán',
    'cong tien hang',
    'cộng tiền hàng',
    'total',
    'net total',
    'grand total',
    'amount due',
    'final amount',
    'sum',
  ];

  // Ignored receipt header keywords for merchant name
  static final List<String> _headerNoiseKeywords = [
    'hoa don',
    'hóa đơn',
    'phieu thanh toan',
    'phiếu thanh toán',
    'phieu thu',
    'phiếu thu',
    'receipt',
    'invoice',
    'tax invoice',
    'bill',
    'welcome',
    'kinh chao',
    'kính chào',
    'dia chi',
    'địa chỉ',
    'hotline',
    'tel',
    'phone',
    'so hoa don',
    'số hóa đơn',
    'ban le',
    'bán lẻ',
    'pos',
  ];

  /// Main parsing routine for OCR extracted text
  static ParsedReceiptResult parse(String fullText) {
    final rawLines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amount = _extractTotalAmount(rawLines);
    final date = _extractDate(rawLines);
    final merchant = _extractMerchant(rawLines);
    final category = _suggestCategory(merchant, rawLines);

    return ParsedReceiptResult(
      amount: amount,
      date: date,
      merchant: merchant,
      suggestedCategory: category,
      rawLines: rawLines,
    );
  }

  /// Extracts total amount using keyword heuristic and amount patterns
  static double? _extractTotalAmount(List<String> lines) {
    double? bestAmount;
    int highestPriority = -1;

    // Regex for amounts: supports 150,000 | 150.000 | 150000 | 150,000.00 with currency suffix/prefix
    final amountPattern = RegExp(
      r'([0-9]{1,3}(?:[.,\s][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]{4,})\s*(?:vnd|vnđ|đ|d|\$)?',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Check if line contains a total keyword
      bool hasTotalKeyword = _totalKeywords.any((kw) => lower.contains(kw));

      // Skip lines indicating cash received or change returned
      if (lower.contains('khach dua') ||
          lower.contains('khách đưa') ||
          lower.contains('tien thua') ||
          lower.contains('tiền thừa') ||
          lower.contains('tien tra') ||
          lower.contains('tiền trả') ||
          lower.contains('change')) {
        continue;
      }

      final matches = amountPattern.allMatches(line);
      for (final match in matches) {
        final rawVal = match.group(1);
        if (rawVal == null) continue;

        final parsed = _normalizeNumber(rawVal);
        if (parsed != null && parsed >= 500 && parsed <= 500000000) {
          int priority = 0;
          if (hasTotalKeyword) {
            priority = 10;
          }

          // If keyword is on the same line or line right after, high confidence
          if (priority > highestPriority) {
            highestPriority = priority;
            bestAmount = parsed;
          } else if (highestPriority <= 0 && (bestAmount == null || parsed > bestAmount)) {
            // Fallback: take maximum reasonable number if no keyword matched
            bestAmount = parsed;
          }
        }
      }
    }

    // Check adjacent line pattern if keyword was separated from amount
    if (highestPriority < 10) {
      for (int i = 0; i < lines.length - 1; i++) {
        final lower = lines[i].toLowerCase();
        if (_totalKeywords.any((kw) => lower.contains(kw))) {
          final nextLine = lines[i + 1];
          final match = amountPattern.firstMatch(nextLine);
          if (match != null) {
            final parsed = _normalizeNumber(match.group(1)!);
            if (parsed != null && parsed >= 500) {
              return parsed;
            }
          }
        }
      }
    }

    return bestAmount;
  }

  /// Normalizes formatted strings into double
  /// E.g. "150,000" -> 150000.0, "150.000" -> 150000.0, "150 000" -> 150000.0
  static double? _normalizeNumber(String raw) {
    String clean = raw.trim().replaceAll(' ', '');
    // If string has both dot and comma (e.g. 150,000.00 or 150.000,00)
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf(',') > clean.lastIndexOf('.')) {
        // European format: 150.000,00 -> 150000.00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US/VN standard: 150,000.00 -> 150000.00
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains('.')) {
      // Could be 150.000 (thousands separator) or 15.50 (decimal)
      final parts = clean.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    return double.tryParse(clean);
  }

  /// Extracts transaction date (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
  static DateTime? _extractDate(List<String> lines) {
    // 1. DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyPattern = RegExp(
      r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b',
    );

    // 2. YYYY/MM/DD or YYYY-MM-DD
    final ymdPattern = RegExp(
      r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b',
    );

    for (final line in lines) {
      final matchDmy = dmyPattern.firstMatch(line);
      if (matchDmy != null) {
        final day = int.parse(matchDmy.group(1)!);
        final month = int.parse(matchDmy.group(2)!);
        final year = int.parse(matchDmy.group(3)!);
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }

      final matchYmd = ymdPattern.firstMatch(line);
      if (matchYmd != null) {
        final year = int.parse(matchYmd.group(1)!);
        final month = int.parse(matchYmd.group(2)!);
        final day = int.parse(matchYmd.group(3)!);
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  /// Extracts merchant name from top lines, ignoring invoice title noise
  static String _extractMerchant(List<String> lines) {
    final candidateLines = lines.take(6).toList();

    for (final line in candidateLines) {
      final lower = line.toLowerCase();
      // Skip very short lines or numbers-only
      if (line.length < 3 || RegExp(r'^[0-9\W]+$').hasMatch(line)) {
        continue;
      }

      // Check if line is generic invoice header noise
      bool isNoise = _headerNoiseKeywords.any((kw) => lower.contains(kw));
      if (!isNoise) {
        return _cleanMerchantName(line);
      }
    }

    return lines.isNotEmpty ? _cleanMerchantName(lines.first) : 'Unknown Merchant';
  }

  static String _cleanMerchantName(String raw) {
    return raw
        .replaceAll(RegExp(r'^[^\w\s]+|[^\w\s]+$'), '')
        .trim();
  }

  /// Suggests category based on merchant name and receipt content keywords
  static ExpenseCategory _suggestCategory(String? merchant, List<String> lines) {
    final fullText = '${merchant ?? ''} ${lines.join(' ')}'.toLowerCase();

    // Food & Dining
    if (fullText.contains('cafe') ||
        fullText.contains('coffee') ||
        fullText.contains('restaurant') ||
        fullText.contains('quán') ||
        fullText.contains('quan') ||
        fullText.contains('cơm') ||
        fullText.contains('phở') ||
        fullText.contains('bún') ||
        fullText.contains('bánh') ||
        fullText.contains('trà sữa') ||
        fullText.contains('highlands') ||
        fullText.contains('starbucks') ||
        fullText.contains('phúc long') ||
        fullText.contains('food') ||
        fullText.contains('kfc') ||
        fullText.contains('lotteria') ||
        fullText.contains('pizza') ||
        fullText.contains('tea')) {
      return ExpenseCategory.food;
    }

    // Study & Books
    if (fullText.contains('sách') ||
        fullText.contains('book') ||
        fullText.contains('nhà sách') ||
        fullText.contains('văn phòng phẩm') ||
        fullText.contains('stationery') ||
        fullText.contains('in ấn') ||
        fullText.contains('photo') ||
        fullText.contains('tuition') ||
        fullText.contains('học phí') ||
        fullText.contains('khóa học')) {
      return ExpenseCategory.study;
    }

    // Travel & Transport
    if (fullText.contains('grab') ||
        fullText.contains('be ') ||
        fullText.contains('xăng') ||
        fullText.contains('petrol') ||
        fullText.contains('vé xe') ||
        fullText.contains('vé tàu') ||
        fullText.contains('vé máy bay') ||
        fullText.contains('taxi') ||
        fullText.contains('hotel') ||
        fullText.contains('travel') ||
        fullText.contains('flight')) {
      return ExpenseCategory.travel;
    }

    // Gear & Hardware
    if (fullText.contains('gear') ||
        fullText.contains('fpt') ||
        fullText.contains('thegioididong') ||
        fullText.contains('tgdd') ||
        fullText.contains('cellphones') ||
        fullText.contains('điện thoại') ||
        fullText.contains('laptop') ||
        fullText.contains('chuột') ||
        fullText.contains('bàn phím') ||
        fullText.contains('tai nghe') ||
        fullText.contains('sạc') ||
        fullText.contains('anker') ||
        fullText.contains('cable')) {
      return ExpenseCategory.gear;
    }

    // Entertainment
    if (fullText.contains('cinema') ||
        fullText.contains('cgv') ||
        fullText.contains('bhd') ||
        fullText.contains('lotte cinema') ||
        fullText.contains('phim') ||
        fullText.contains('game') ||
        fullText.contains('karaoke') ||
        fullText.contains('billiards') ||
        fullText.contains('bowling')) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food;
  }
}
