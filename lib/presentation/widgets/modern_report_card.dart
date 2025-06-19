import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_sizes.dart';
import '../../core/services/theme.dart';
import '../../models/report_model.dart';
import '../../core/extensions/date_extensions.dart';

/// Modern report card widget with admin panel design
class ModernReportCard extends StatelessWidget {
  final Report report;

  const ModernReportCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmergency = report.priority == 'Emergency';
    AppSizes.init(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/report-details', extra: report),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (isEmergency ? AppColors.error : AppColors.primary)
                      .withOpacity(0.02),
                ],
              ),
              border: Border.all(
                color: isEmergency
                    ? AppColors.error.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                width: isEmergency ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isEmergency ? AppColors.error : AppColors.primary)
                      .withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isEmergency),
                  _buildContent(theme),
                  _buildFooter(theme, context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isEmergency) {
    final headerColor = isEmergency ? AppColors.error : AppColors.primary;
    final formattedDate = report.scheduledDate.dateCategory;

    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            headerColor.withOpacity(0.1),
            headerColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: headerColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isEmergency ? Icons.warning_rounded : Icons.info_rounded,
              color: Colors.white,
              size: AppSizes.blockWidth * 5,
            ),
          ),
          SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? 'طارئ' : 'روتيني',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: headerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.blockHeight * 1.8,
                  ),
                ),
                Text(
                  'تقرير رقم ${report.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: headerColor.withOpacity(0.7),
                    fontSize: AppSizes.blockHeight * 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: AppPadding.small * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: headerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: headerColor,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.blockHeight * 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            theme,
            'المدرسة',
            report.schoolName,
            Icons.school_rounded,
            AppColors.secondary,
          ),
          SizedBox(height: AppPadding.small),
          _buildInfoRow(
            theme,
            'النوع',
            report.type,
            Icons.category_rounded,
            AppColors.warning,
          ),
          SizedBox(height: AppPadding.small),
          _buildInfoRow(
            theme,
            'المشرف',
            report.supervisorName,
            Icons.person_rounded,
            AppColors.primary,
          ),
          SizedBox(height: AppPadding.medium),
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                      size: AppSizes.blockWidth * 4,
                    ),
                    SizedBox(width: AppPadding.small),
                    Text(
                      'الوصف',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppPadding.small),
                Text(
                  report.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppPadding.small * 0.8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppSizes.blockWidth * 4,
          ),
        ),
        SizedBox(width: AppPadding.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: AppSizes.blockHeight * 1.2,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.blockHeight * 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildStatusChip(theme),
          const Spacer(),
          if (report.status.toLowerCase() != 'completed')
            _buildActionButton(theme, context),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color statusColor;
    String statusText;

    switch (report.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'مكتمل';
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusText = 'قيد الانتظار';
        break;
      case 'late':
        statusColor = AppColors.error;
        statusText = 'متأخر';
        break;
      case 'issues':
        statusColor = AppColors.error;
        statusText = 'مشاكل';
        break;
      default:
        statusColor = Colors.grey;
        statusText = report.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppPadding.small),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.blockHeight * 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/completion-screen', extra: report),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: AppSizes.blockWidth * 4,
              ),
              SizedBox(width: AppPadding.small),
              Text(
                'إكمال',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.blockHeight * 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 