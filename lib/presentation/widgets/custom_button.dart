import 'package:flutter/material.dart';

import '../../core/utils/app_sizes.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
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
        horizontal: AppSizes.blockWidth * 4,
        vertical: AppSizes.blockHeight * 1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: AppSizes.blockHeight * 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  color?.withValues(alpha: 0.9) ??
                      theme.primaryColor.withValues(alpha: 0.9),
                  color?.withValues(alpha: 0.7) ??
                      theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (color ?? theme.primaryColor).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.blockWidth * 6,
                vertical: AppSizes.blockHeight * 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.blockHeight * 2.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(AppSizes.blockWidth * 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/$icon.png',
                      height: AppSizes.blockWidth * 8,
                      width: AppSizes.blockWidth * 8,
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
