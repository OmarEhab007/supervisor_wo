import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/app_sizes.dart';
import '../../core/services/theme.dart';
import '../../models/maintenance_report_model.dart';

/// Builds a simplified maintenance report card without type and priority containers
/// Used for maintenance report details screens
Widget buildSimplifiedMaintenanceCard(
  BuildContext context,
  MaintenanceReport report, {
  required VoidCallback onTap,
}) {
  AppSizes.init(context);
  
  // Format dates
  final createdDate = _formatDate(report.createdAt);
  final closedDate = report.closedAt != null ? _formatDate(report.closedAt!) : null;
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with creation date
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        createdDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppPadding.medium),
            
            // Description
            Text(
              report.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E293B),
                height: 1.4,
              ),
            ),
            SizedBox(height: AppPadding.medium),
            
            // Images preview if available
            if (report.images.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'الصور المرفقة (${report.images.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(report.images[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppPadding.medium),
            ],
            
            // Completion photos if available
            if (report.completionPhotos.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'صور الإكمال (${report.completionPhotos.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.completionPhotos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(report.completionPhotos[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppPadding.medium),
            ],
            
            // Completion note if available
            if (report.completionNote != null && report.completionNote!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppPadding.medium),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات الإكمال:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      report.completionNote!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppPadding.medium),
            ],
            
            // Status indicator at bottom
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(report.status),
                        size: 12,
                        color: _getStatusColor(report.status),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getStatusText(report.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(report.status),
                        ),
                      ),
                    ],
                  ),
                ),
                if (report.status == 'completed' && closedDate != null) ...[
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 12,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          closedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'completed':
      return AppColors.success;
    case 'pending':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

IconData _getStatusIcon(String status) {
  switch (status) {
    case 'completed':
      return Icons.check_circle_rounded;
    case 'pending':
      return Icons.schedule_rounded;
    default:
      return Icons.assignment_rounded;
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'completed':
      return 'مكتمل';
    case 'pending':
      return 'معلق';
    default:
      return 'جديد';
  }
}
