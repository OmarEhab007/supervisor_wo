import 'package:flutter/material.dart';

import '../../core/utils/app_sizes.dart';

class CustomCardButton extends StatelessWidget {
  const CustomCardButton({
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: AppSizes.blockHeight * 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
              // border: Border.all(
              //   color: (color ?? theme.primaryColor).withValues(alpha: 0.2),
              //   width: 1.5,
              // ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withValues(alpha: 0.06),
                //     blurRadius: 12,
                //     offset: const Offset(0, 2),
                //   ),
                //   BoxShadow(
                //     color: Colors.black.withValues(alpha: 0.04),
                //     blurRadius: 6,
                //     offset: const Offset(0, 1),
                //   ),
                // ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSizes.blockWidth * 4),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: AppSizes.blockWidth * 14,
                    height: AppSizes.blockWidth * 14,
                    decoration: BoxDecoration(
                      color:
                          (color ?? theme.primaryColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/$icon.png',
                        height: AppSizes.blockWidth * 8,
                        width: AppSizes.blockWidth * 8,
                      ),
                    ),
                  ),

                  SizedBox(width: AppSizes.blockWidth * 4),

                  // Title and Arrow
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSizes.blockHeight * 2.2,
                            ),
                          ),
                        ),

                        // Arrow Icon
                        Container(
                          padding: EdgeInsets.all(AppSizes.blockWidth * 2),
                          decoration: BoxDecoration(
                            color: (color ?? theme.primaryColor)
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: AppSizes.blockWidth * 4,
                            color: color ?? theme.primaryColor,
                          ),
                        ),
                      ],
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
