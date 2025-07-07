import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/presentation/widgets/image_picker_widget.dart';

import '../../core/utils/app_sizes.dart';
import '../screens/maintenance_completion_screen.dart';

Widget buildMaintenanceCompletionFormCard(
    BuildContext context, ThemeData theme, MaintenanceCompletionState state) {
  final cubit = context.read<MaintenanceCompletionCubit>();
  AppSizes.init(context);

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.white, Colors.grey[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Gradient Background
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات إنجاز الصيانة',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: AppPadding.small),
                      Text(
                        'أكمل البيانات المطلوبة لإغلاق بلاغ الصيانة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Note Section
                buildSectionHeader(
                  'ملاحظات الإنجاز',
                  Icons.note_alt_outlined,
                  theme,
                ),
                SizedBox(height: AppPadding.medium),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'أدخل ملاحظات حول ما تم إنجازه في الصيانة',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppPadding.medium),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    maxLines: 4,
                    textDirection: TextDirection.rtl,
                    onChanged: cubit.completionNoteChanged,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: AppPadding.large + 8),

                // Completion Photos Section
                buildSectionHeader(
                  'صور إنجاز الصيانة',
                  Icons.camera_alt_outlined,
                  theme,
                ),
                SizedBox(height: AppPadding.small),

                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: AppPadding.small),
                      Expanded(
                        child: Text(
                          'يرجى إضافة صور توثق إنجاز أعمال الصيانة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppPadding.medium),

                // Image Picker Widget
                ImagePickerWidget(
                  // maxImages removed to use unlimited default
                  images: state.completionPhotos,
                  onImagesChanged: (images) {
                    // Just store the local image paths, don't upload immediately
                    cubit.completionPhotosChanged(images);
                  },
                ),

                SizedBox(height: AppPadding.medium),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildSectionHeader(String title, IconData icon, ThemeData theme) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      SizedBox(width: AppPadding.small),
      Expanded(
        child: Text(
          title,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}
