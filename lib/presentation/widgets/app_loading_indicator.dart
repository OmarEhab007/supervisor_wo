import 'package:flutter/material.dart';
import 'package:supervisor_wo/utils/app_sizes.dart';

/// A reusable loading indicator widget with consistent styling
class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Initialize AppSizes if not already initialized
    AppSizes.init(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? AppSizes.blockWidth * 10,
            height: size ?? AppSizes.blockWidth * 10,
            child: CircularProgressIndicator(
              color: color ?? theme.primaryColor,
              strokeWidth: strokeWidth ?? 3,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppPadding.medium),
            Text(
              message!,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: AppSizes.blockWidth * 4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
