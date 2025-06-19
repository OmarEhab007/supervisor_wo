import 'package:intl/intl.dart';

/// Extension methods for DateTime to provide helper methods for date categorization
extension DateTimeExtensions on DateTime {
  /// Returns a string representing the date category (today, tomorrow, after tomorrow)
  String get dateCategory {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final afterTomorrow = today.add(const Duration(days: 2));
    
    final compareDate = DateTime(year, month, day);
    
    if (compareDate.isAtSameMomentAs(today)) {
      return 'اليوم';
    } else if (compareDate.isAtSameMomentAs(tomorrow)) {
      return 'غداً';
    } else if (compareDate.isAtSameMomentAs(afterTomorrow)) {
      return 'بعد غد';
    } else {
      // For dates beyond after tomorrow, return formatted date
      return DateFormat('yyyy/MM/dd').format(this);
    }
  }
  
  /// Returns true if the date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Returns true if the date is tomorrow
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  /// Returns true if the date is after tomorrow
  bool get isAfterTomorrow {
    final now = DateTime.now();
    final afterTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
    return year == afterTomorrow.year && month == afterTomorrow.month && day == afterTomorrow.day;
  }
}
