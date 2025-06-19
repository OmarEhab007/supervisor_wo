import 'package:flutter/material.dart';

import '../../core/utils/app_sizes.dart';

class CustomGridButton extends StatelessWidget {
  const CustomGridButton({
    super.key,
    required this.onTap,
    required this.title,
    required this.icon,
    this.color,
  });

  final VoidCallback onTap;
  final String title;
  final String icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AppSizes.init(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.blockWidth * 20,
        vertical: AppSizes.blockHeight * 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: AppSizes.blockHeight * 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSizes.blockWidth * 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    width: AppSizes.blockWidth * 16,
                    height: AppSizes.blockWidth * 16,
                    decoration: BoxDecoration(
                      color:
                          (color ?? theme.primaryColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/$icon.png',
                        height: AppSizes.blockWidth * 10,
                        width: AppSizes.blockWidth * 10,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSizes.blockHeight * 2),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: const Color(0xFF2C3E50),
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.blockHeight * 2,
                    ),
                  ),

                  SizedBox(height: AppSizes.blockHeight * 1),

                  // Bottom accent line
                  Container(
                    width: AppSizes.blockWidth * 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color ?? theme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
