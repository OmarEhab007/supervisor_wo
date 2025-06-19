import 'package:flutter/material.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

/// Utility class for converting static sizes to responsive sizes
class ResponsiveUtils {
  /// Convert a static font size to a responsive one
  static double fontSize(double staticSize) {
    // Scale based on screen width, with minimum and maximum constraints
    return (staticSize / 16) * AppSizes.blockWidth * 1.6;
  }

  /// Convert a static size (width, height, radius, etc.) to a responsive one
  static double size(double staticSize) {
    // Scale based on screen width, with minimum and maximum constraints
    return (staticSize / 16) * AppSizes.blockWidth * 1.6;
  }

  /// Convert static padding to responsive padding
  static EdgeInsetsGeometry padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(size(all));
    }
    
    return EdgeInsets.only(
      left: left != null ? size(left) : horizontal != null ? size(horizontal) : 0,
      top: top != null ? size(top) : vertical != null ? size(vertical) : 0,
      right: right != null ? size(right) : horizontal != null ? size(horizontal) : 0,
      bottom: bottom != null ? size(bottom) : vertical != null ? size(vertical) : 0,
    );
  }

  /// Convert static margin to responsive margin
  static EdgeInsetsGeometry margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return padding(
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Convert static radius to responsive radius
  static BorderRadius radius(double radius) {
    return BorderRadius.circular(size(radius));
  }

  /// Get a responsive SizedBox with height
  static SizedBox height(double height) {
    return SizedBox(height: size(height));
  }

  /// Get a responsive SizedBox with width
  static SizedBox width(double width) {
    return SizedBox(width: size(width));
  }

  /// Get a responsive icon size
  static double iconSize(double size) {
    return ResponsiveUtils.size(size);
  }

  /// Get a responsive blur radius
  static double blurRadius(double radius) {
    return size(radius);
  }
}

/// Extension methods for responsive sizing
extension ResponsiveExtension on num {
  /// Convert to responsive font size
  double get rFontSize => ResponsiveUtils.fontSize(toDouble());
  
  /// Convert to responsive size
  double get rSize => ResponsiveUtils.size(toDouble());
  
  /// Get responsive height SizedBox
  SizedBox get rHeight => ResponsiveUtils.height(toDouble());
  
  /// Get responsive width SizedBox
  SizedBox get rWidth => ResponsiveUtils.width(toDouble());
  
  /// Get responsive blur radius
  double get rBlur => ResponsiveUtils.blurRadius(toDouble());
  
  /// Get responsive icon size
  double get rIconSize => ResponsiveUtils.iconSize(toDouble());
}
