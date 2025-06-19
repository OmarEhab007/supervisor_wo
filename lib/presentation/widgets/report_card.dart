import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import '../../core/utils/app_sizes.dart';
import '../../models/report_model.dart';
import '../screens/report_images_screen.dart';

class ReportCard extends StatelessWidget {
  final Report report;

  const ReportCard({super.key, required this.report});

  // Static date formatter to avoid recreating on every build
  static final _dateFormatter = intl.DateFormat('dd/MM/yyyy-HH:mm a');

  // Static initialization flag to avoid repeated calls
  static bool _isDateFormattingInitialized = false;

  // Cache expensive computations
  static const Map<String, String> _typeTranslations = {
    'Civil': 'مدني',
    'Plumbing': 'سباكة',
    'Electricity': 'كهرباء',
    'AC': 'تكييف',
    'Fire': 'حريق',
  };

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
    final formattedDate =  _dateFormatter.format(timestamp) ;
    final isEmergency = report.priority == 'Emergency';
    final isCompleted = report.status == 'completed' || report.status == 'late_completed';

    AppSizes.init(context);

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => context.push('/completion-screen', extra: report),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEmergency 
                    ? const Color(0xffFF4757).withOpacity(0.15)
                    : const Color(0xffE2E8F0),
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
                    _buildStatusIndicator(isEmergency, isCompleted),
                    SizedBox(width: AppPadding.extraSmall),
                    Expanded(
                      child: Text(
                        report.schoolName,
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
                        _translateType(report.type),
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
                                    //decoration: TextDecoration.underline,
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

  Widget _buildStatusIndicator(bool isEmergency, bool isCompleted) {
    Color color;
    IconData icon;

    if (report.status == 'late_completed') {
      // Orange clock indicator for late completed reports
      color = const Color(0xffF59E0B); // Orange color matching the warning theme
      icon = Icons.schedule_rounded;
    } else if (isCompleted) {
      // Green check circle for regular completed reports
      color = const Color(0xff10B981);
      icon = Icons.check_circle;
    } else if (isEmergency) {
      color = const Color(0xffFF4757);
      icon = Icons.warning;
    } else {
      color = const Color(0xff3B82F6);
      icon = Icons.info;
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
      case 'late':
        statusColor = const Color(0xffEF4444);
        statusText = 'متأخر';
        break;
      
      case 'late_completed':
        statusColor =  Colors.orange;
        statusText = 'مكتمل متأخر';
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
      onTap: () => context.push('/completion-screen', extra: report),
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

  String _translateType(String type) {
    return _typeTranslations[type] ?? type;
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

