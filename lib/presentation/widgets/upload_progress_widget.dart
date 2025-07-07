import 'package:flutter/material.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

class UploadProgressWidget extends StatelessWidget {
  final int completed;
  final int total;
  final String currentSection;
  final bool isVisible;

  const UploadProgressWidget({
    super.key,
    required this.completed,
    required this.total,
    required this.currentSection,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || total == 0) return const SizedBox.shrink();

    AppSizes.init(context);
    final progress = completed / total;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: EdgeInsets.all(AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.blockWidth * 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: AppSizes.blockWidth * 2,
            offset: Offset(0, AppSizes.blockHeight * 0.3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                color: Colors.orange,
                size: AppSizes.blockWidth * 6,
              ),
              SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  'جاري رفع الصور...',
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: AppSizes.blockHeight * 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.small),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: AppSizes.blockHeight * 0.8,
          ),
          SizedBox(height: AppPadding.small * 0.7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'القسم الحالي: $currentSection',
                style: TextStyle(
                  fontSize: AppSizes.blockHeight * 1.5,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$completed من $total صورة',
                style: TextStyle(
                  fontSize: AppSizes.blockHeight * 1.5,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UploadProgressDialog extends StatelessWidget {
  final int completed;
  final int total;
  final String currentSection;

  const UploadProgressDialog({
    super.key,
    required this.completed,
    required this.total,
    required this.currentSection,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    final progress = total > 0 ? completed / total : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.blockWidth * 4)),
      child: Container(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              color: Colors.orange,
              size: AppSizes.blockWidth * 12,
            ),
            SizedBox(height: AppPadding.medium),
            Text(
              'جاري رفع الصور',
              style: TextStyle(
                fontSize: AppSizes.blockHeight * 2.2,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'يرجى الانتظار حتى انتهاء رفع جميع الصور',
              style: TextStyle(
                fontSize: AppSizes.blockHeight * 1.7,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.large),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: AppSizes.blockHeight * 1,
            ),
            SizedBox(height: AppPadding.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '$completed من $total',
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * 1.7,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (currentSection.isNotEmpty) ...[
              SizedBox(height: AppPadding.small),
              Text(
                'القسم الحالي: $currentSection',
                style: TextStyle(
                  fontSize: AppSizes.blockHeight * 1.5,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UploadProgressDialog(
        completed: 0,
        total: 1,
        currentSection: '',
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
