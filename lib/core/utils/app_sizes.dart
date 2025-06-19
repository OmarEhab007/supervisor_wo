import 'package:flutter/material.dart';

/// Utility class for responsive sizing
class AppSizes {
  /// Screen width
  static late double screenWidth;
  
  /// Screen height
  static late double screenHeight;
  
  /// Block width (1% of screen width)
  static late double blockWidth;
  
  /// Block height (1% of screen height)
  static late double blockHeight;
  
  /// Padding values for backward compatibility
  static late double paddingSmall;
  static late double paddingMedium;
  static late double paddingLarge;
  
  /// Initialize the sizes based on the context
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    blockWidth = screenWidth / 100;
    blockHeight = screenHeight / 100;
    
    // Initialize padding values for backward compatibility
    paddingSmall = blockWidth * 2;
    paddingMedium = blockWidth * 4;
    paddingLarge = blockWidth * 6;
  }
}

/// Padding values used throughout the app
class AppPadding {
  /// Extra small padding
  static double get extraSmall => AppSizes.blockWidth * 1;
  
  /// Small padding
  static double get small => AppSizes.blockWidth * 2;
  
  /// Medium padding
  static double get medium => AppSizes.blockWidth * 4;
  
  /// Large padding
  static double get large => AppSizes.blockWidth * 6;
  
  /// Extra large padding
  static double get extraLarge => AppSizes.blockWidth * 8;
}

/// Extension methods for Color
extension ColorExtension on Color {
  /// Returns a new color with the specified alpha value
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
      alpha ?? this.opacity,
    );
  }
}
