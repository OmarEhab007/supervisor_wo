import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_sizes.dart';
import '../../core/services/theme.dart';

Widget buildModernSchoolCard(BuildContext context, String schoolName,
    int reportCount, bool hasEmergency, ColorScheme colorScheme,
    {required VoidCallback onTap, Color? color}) {
  AppSizes.init(context);
  
  return Container(
    margin: EdgeInsets.only(bottom: AppPadding.medium),
    child: Material(
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
            border: Border.all(
              color: hasEmergency 
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff1A1A1A).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (hasEmergency) ...[
                BoxShadow(
                  color: AppColors.error.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ],
          ),
          child: Row(
            children: [
              // Modern school icon with enhanced styling
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: hasEmergency ? [
                      AppColors.error,
                      AppColors.error.withOpacity(0.8),
                    ] : [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: hasEmergency 
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              // School information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School name
                    Text(
                      schoolName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E293B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppPadding.small),
                    // Status indicators row
                    Row(
                      children: [
                        // Reports count chip
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_rounded,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$reportCount بلاغ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppPadding.small),
                        // Emergency status chip
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasEmergency 
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasEmergency 
                                  ? AppColors.error.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasEmergency ? Icons.warning_rounded : Icons.info_rounded,
                                size: 14,
                                color: hasEmergency ? AppColors.error : AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                hasEmergency ? 'طوارئ' : 'روتيني',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: hasEmergency ? AppColors.error : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppPadding.small),
              // Modern arrow indicator
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                  size: AppSizes.blockHeight * 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
