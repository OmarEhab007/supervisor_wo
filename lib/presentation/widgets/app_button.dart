import 'package:flutter/material.dart';
import 'package:supervisor_wo/utils/app_sizes.dart';

/// A reusable button widget with consistent styling
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? color;
  final IconData? icon;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.color,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Initialize AppSizes if not already initialized
    AppSizes.init(context);

    return SizedBox(
      width: width,
      height: height ?? AppSizes.blockHeight * 6,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
          elevation: 3,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSizes.blockWidth * 5),
                    SizedBox(width: AppPadding.small),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: AppSizes.blockWidth * 4,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
