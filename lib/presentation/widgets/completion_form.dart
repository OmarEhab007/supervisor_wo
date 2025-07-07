import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/presentation/widgets/image_picker_widget.dart';

import '../../core/blocs/reports/reports_bloc.dart';
import '../../core/blocs/reports/reports_event.dart';
import '../../core/services/cloudinary_service.dart';
import '../../utils/app_sizes.dart';
import '../../utils/app_toast.dart';
import '../screens/report_completion_screen.dart';

Widget buildCompletionFormCard(
    BuildContext context, ThemeData theme, ReportCompletionState state) {
  final cubit = context.read<ReportCompletionCubit>();
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A2F59),
                  const Color(0xFF2A4B7C),
                  const Color(0xFF3A5F9F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                        'معلومات الإنجاز',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: AppPadding.small),
                      Text(
                        'أكمل البيانات المطلوبة لإغلاق البلاغ',
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
                  'ملاحظات الإغلاق',
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
                      hintText: 'أدخل ملاحظات حول ما تم إنجازه',
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
                          color: const Color(0xFF1A2F59).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: const Color(0xFF1A2F59),
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
                  'صور الإنجاز',
                  Icons.camera_alt_outlined,
                  theme,
                ),
                SizedBox(height: AppPadding.small),

                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue[100]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      SizedBox(width: AppPadding.small),
                      Expanded(
                        child: Text(
                          'يرجى إضافة صور توثق إنجاز البلاغ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppPadding.medium),

                // Enhanced Image Picker Container
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ImagePickerWidget(
                    images: state.completionPhotos,
                    onImagesChanged: cubit.completionPhotosChanged,
                    // maxImages removed to use unlimited default
                  ),
                ),

                // Error Message with Enhanced Styling
                if (state.errorMessage != null)
                  Container(
                    margin: EdgeInsets.only(top: AppPadding.medium),
                    padding: EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        SizedBox(width: AppPadding.small),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
          color: const Color(0xFF1A2F59).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF1A2F59),
          size: 20,
        ),
      ),
      SizedBox(width: 12),
      Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A2F59),
          fontSize: 16,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );
}

Widget buildDetailRow(String label, String value, ThemeData theme,
    {bool isMultiLine = false}) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 6),
    padding: EdgeInsets.all(AppPadding.medium),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey[200]!,
        width: 1,
      ),
    ),
    child: Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2F59).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2F59),
              fontSize: 13,
            ),
          ),
        ),
        SizedBox(width: AppPadding.medium),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

String getPriorityText(String priority) {
  switch (priority) {
    case 'high':
      return 'عالية';
    case 'medium':
      return 'متوسطة';
    case 'low':
      return 'منخفضة';
    default:
      return priority;
  }
}

String getStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'قيد الانتظار';
    case 'in_progress':
      return 'قيد التنفيذ';
    case 'completed':
      return 'مكتمل';
    case 'late':
      return 'متأخر';
    case 'late_completed':
      return 'مكتمل متأخر';
    default:
      return status;
  }
}

String formatDate(DateTime date) {
  return '${date.year}/${date.month}/${date.day}';
}

Future<void> handleCompletion(
    BuildContext context, ReportCompletionState state, dynamic report) async {
  if (!state.isValid) return;

  final navigator = Navigator.of(context);

  // Show enhanced loading indicator with progress
  int uploadProgress = 0;
  int totalImages =
      state.completionPhotos.where((path) => !path.startsWith('http')).length;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(AppPadding.large * 1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  strokeWidth: 3.5,
                ),
                SizedBox(height: AppPadding.large),
                Text(
                  totalImages > 0
                      ? 'جاري رفع الصور ($uploadProgress/$totalImages)'
                      : 'جاري إكمال البلاغ...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        const Color(0xFF1A2F59),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (totalImages > 0) ...[
                  SizedBox(height: AppPadding.medium),
                  LinearProgressIndicator(
                    value: totalImages > 0 ? uploadProgress / totalImages : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                ],
                SizedBox(height: AppPadding.small),
                Text(
                  'يرجى الانتظار، سيتم إكمال البلاغ تلقائياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  try {
    // Upload images in parallel with progress tracking
    List<String> uploadedUrls = [];

    if (state.completionPhotos.isNotEmpty) {
      uploadedUrls = await CloudinaryService.uploadImagesInParallel(
        state.completionPhotos,
        onProgress: (completed, total) {
          uploadProgress = completed;
          // Trigger a rebuild of the StatefulBuilder
          if (context.mounted) {
            (context as Element).markNeedsBuild();
          }
        },
      );
    }

    // Pop the dialog after successful uploads
    if (navigator.canPop()) {
      navigator.pop();
    }

    context.read<ReportsBloc>().add(
          ReportCompleted(
            reportId: report.id,
            completionNote: state.completionNote,
            completionPhotos: uploadedUrls,
          ),
        );
  } catch (e) {
    // Pop the dialog in case of an error
    if (navigator.canPop()) {
      navigator.pop();
    }
    AppToast.showError(context, 'فشل في رفع الصور: ${e.toString()}');
  }
}
