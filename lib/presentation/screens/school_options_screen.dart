import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/theme.dart';
import '../../core/utils/app_sizes.dart';
import '../../models/school_model.dart';
import '../../models/school_achievement_model.dart';
import 'school_achievement_upload_screen.dart';
import '../widgets/gradient_app_bar.dart';

class SchoolOptionsScreen extends StatelessWidget {
  final School school;

  const SchoolOptionsScreen({
    super.key,
    required this.school,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: school.name,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // School info card
                Container(
                  padding: EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
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
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: AppPadding.large),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              school.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (school.address.isNotEmpty) ...[
                              SizedBox(height: AppPadding.small),
                              Text(
                                school.address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xff6B7280),
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: AppPadding.small),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  school.lastVisitDate != null
                                      ? 'آخر زيارة: ${school.lastVisitDate!.day}/${school.lastVisitDate!.month}/${school.lastVisitDate!.year}${school.lastVisitSource != null ? ' (${school.lastVisitSource})' : ''}'
                                      : 'لم تتم الزيارة بعد',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppPadding.extraLarge),

                // Options title
                Text(
                  'اختر العملية المطلوبة',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppPadding.large),

                // Options buttons
                Expanded(
                  child: Column(
                    children: [
                      // Achievement View Option
                      _buildOptionCard(
                        context: context,
                        title: 'مشهد انجاز',
                        subtitle: 'رفع صور المشهد الانجاز',
                        icon: Icons.analytics_rounded,
                        color: AppColors.primary,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Show achievement options dialog
                          _showAchievementOptions(context);
                        },
                      ),

                      SizedBox(height: AppPadding.large),

                      // Checklist Option
                      _buildOptionCard(
                        context: context,
                        title: 'تشيك ليست',
                        subtitle: 'رفع صور التشيك ليست',
                        icon: Icons.camera_alt_rounded,
                        color: AppColors.secondary,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Go directly to photo upload for checklist
                          _showPhotoUpload(context, 'تشيك ليست');
                        },
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(AppPadding.large),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              SizedBox(width: AppPadding.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    SizedBox(height: AppPadding.small),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xff6B7280),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر نوع مشهد الانجاز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAchievementOption(
                context: context,
                title: 'مشهد انجاز صيانة',
                subtitle: 'رفع صور انجاز الصيانة',
                icon: Icons.build_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  _showPhotoUpload(context, 'مشهد انجاز صيانة');
                },
              ),
              SizedBox(height: AppPadding.medium),
              _buildAchievementOption(
                context: context,
                title: 'مشهد انجاز تكييف',
                subtitle: 'رفع صور انجاز التكييف',
                icon: Icons.ac_unit_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  _showPhotoUpload(context, 'مشهد انجاز تكييف');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoUpload(BuildContext context, String type) {
    // Determine achievement type based on the type string
    AchievementType achievementType;
    switch (type) {
      case 'مشهد انجاز صيانة':
        achievementType = AchievementType.maintenanceAchievement;
        break;
      case 'مشهد انجاز تكييف':
        achievementType = AchievementType.acAchievement;
        break;
      case 'تشيك ليست':
        achievementType = AchievementType.checklist;
        break;
      default:
        achievementType = AchievementType.checklist;
    }

    // Navigate to upload screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SchoolAchievementUploadScreen(
          school: school,
          achievementType: achievementType,
        ),
      ),
    );
  }

  Widget _buildAchievementOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xff6B7280),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
