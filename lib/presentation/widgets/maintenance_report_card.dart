import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import '../../core/utils/app_sizes.dart';
import '../../models/maintenance_report_model.dart';
import '../screens/report_images_screen.dart';

class MaintenanceReportCard extends StatelessWidget {
  final MaintenanceReport report;

  const MaintenanceReportCard({super.key, required this.report});

  // Static date formatter to avoid recreating on every build
  static final _dateFormatter = intl.DateFormat('dd/MM/yyyy-HH:mm a');

  // Static initialization flag to avoid repeated calls
  static bool _isDateFormattingInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Initialize date formatting only once
    if (!_isDateFormattingInitialized) {
      initializeDateFormatting('ar', null);
      _isDateFormattingInitialized = true;
    }

    final hasImages = report.images.isNotEmpty;
    final timestamp = report.createdAt;
    final completedAt = report.closedAt;
    final formattedCompletedAt = completedAt != null ? _dateFormatter.format(completedAt) : 'غير محدد';
    final formattedDate =  _dateFormatter.format(timestamp);
    final isCompleted = report.status == 'completed';

    AppSizes.init(context);

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => context.push('/maintenance-completion-screen', extra: report),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1A1A1A).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // First row: Status icon + School name + Date
                Row(
                  children: [
                    _buildStatusIndicator(isCompleted),
                    SizedBox(width: AppPadding.extraSmall),
                    Expanded(
                      child: Text(
                        report.schoolId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        completedAt != null ? '$formattedCompletedAt  : مكتمل في'  : formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppPadding.medium),
                // Full-width description
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff475569),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppPadding.medium),
                // Bottom row: Status + Type chips on left, Images + Action on right
                Row(
                  children: [
                    // Left side: Status and Type chips
                    _buildStatusChip(),
                    SizedBox(width: AppPadding.small),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'صيانة دورية',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff64748B),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Right side: Images indicator and Action button
                    if (hasImages) ...[
                      GestureDetector(
                        onTap: () => _showImages(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 14,
                                color: const Color(0xff3B82F6),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${report.images.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff3B82F6),
                                ),
                              ),
                              SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showImages(context),
                                child: Text(
                                  'عرض',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: AppPadding.small),
                    ],
                    if (!isCompleted) _buildActionButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isCompleted) {
    Color color;
    IconData icon;

    if (isCompleted) {
      // Green check circle for completed maintenance reports
      color = const Color(0xff10B981);
      icon = Icons.check_circle;
    } else {
      // Blue build icon for pending maintenance reports
      color = const Color(0xff3B82F6);
      icon = Icons.build;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;

    switch (report.status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xff10B981);
        statusText = 'مكتمل';
        break;
      case 'pending':
        statusColor = const Color(0xffF59E0B);
        statusText = 'انتظار';
        break;
      case 'in_progress':
        statusColor = const Color(0xff3B82F6);
        statusText = 'قيد التنفيذ';
        break;
      default:
        statusColor = const Color(0xff6B7280);
        statusText = report.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/maintenance-completion-screen', extra: report),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xff3B82F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'إكمال',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showImages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportImagesScreen(
          images: report.images,
        ),
      ),
    );
  }
}
