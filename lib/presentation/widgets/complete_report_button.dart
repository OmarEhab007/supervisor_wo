import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompleteReportButton extends StatelessWidget {
  final dynamic report;
  final VoidCallback? onPressed;
  final String? customText;
  final IconData? customIcon;
  final bool isLoading;

  const CompleteReportButton({
    super.key,
    required this.report,
    this.onPressed,
    this.customText,
    this.customIcon,
    this.isLoading = false,
  });

  void _handleTap(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else {
      context.push('/completion-screen', extra: report);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isLoading ? null : () => _handleTap(context),
          borderRadius: BorderRadius.circular(8),
          splashColor: theme.primaryColor.withOpacity(0.1),
          highlightColor: theme.primaryColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLoading
                    ? Colors.grey.withOpacity(0.3)
                    : theme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
              color: isLoading
                  ? (isDark ? Colors.grey[800] : Colors.grey[50])
                  : theme.primaryColor.withOpacity(0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        )
                      : Icon(
                          customIcon ?? Icons.check_circle_outline_rounded,
                          color:
                              isLoading ? Colors.grey[600] : theme.primaryColor,
                          size: 18,
                        ),
                ),

                const SizedBox(width: 12),

                // Text
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isLoading ? Colors.grey[600] : theme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ) ??
                      const TextStyle(),
                  child: Text(
                    'إغلاق البلاغ',
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isLoading ? 0.25 : 0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isLoading ? Colors.grey[600] : theme.primaryColor,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
