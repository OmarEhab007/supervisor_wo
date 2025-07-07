import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:equatable/equatable.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/presentation/widgets/app_loading_indicator.dart';
import 'package:supervisor_wo/presentation/widgets/image_picker_widget.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/utils/app_sizes.dart';
import 'package:supervisor_wo/utils/app_toast.dart';
import 'package:supervisor_wo/core/services/cloudinary_service.dart';

class ReportCompletionScreen extends StatefulWidget {
  final Report report;

  const ReportCompletionScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportCompletionScreen> createState() => _ReportCompletionScreenState();
}

class _ReportCompletionScreenState extends State<ReportCompletionScreen> {
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsBloc>().add(ReportsStatusCleared());
    });
  }

  void _handleCompletion(ReportCompletionState state, dynamic report) async {
    setState(() => _submitted = true);

    try {
      // Show loading dialog with upload progress
      int uploadProgress = 0;
      int totalImages = state.completionPhotos
          .where((path) => !path.startsWith('http'))
          .length;

      late StateSetter dialogSetState;
      if (totalImages > 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => StatefulBuilder(
            builder: (context, setState) {
              dialogSetState = setState;
              return Dialog(
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
                          value: totalImages > 0
                              ? uploadProgress / totalImages
                              : null,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 3.5,
                        ),
                        SizedBox(height: AppPadding.large),
                        Text(
                          'جاري رفع الصور ($uploadProgress/$totalImages)',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                        ),
                        SizedBox(height: AppPadding.medium),
                        LinearProgressIndicator(
                          value: totalImages > 0
                              ? uploadProgress / totalImages
                              : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: AppPadding.small),
                        Text(
                          'يرجى الانتظار، سيتم إكمال البلاغ تلقائياً',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      // Upload images in parallel first
      List<String> uploadedPhotos = [];

      if (state.completionPhotos.isNotEmpty) {
        uploadedPhotos = await CloudinaryService.uploadImagesInParallel(
          state.completionPhotos,
          onProgress: (completed, total) {
            uploadProgress = completed;
            // Trigger a rebuild of the dialog
            if (totalImages > 0) {
              dialogSetState(() {});
            }
          },
        );
      }

      // Close the upload dialog if it was shown
      if (totalImages > 0 && mounted) {
        Navigator.of(context).pop();
      }

      // Dispatch completion event with uploaded URLs
      context.read<ReportsBloc>().add(
            ReportCompleted(
              reportId: report.id,
              completionNote: state.completionNote,
              completionPhotos: uploadedPhotos,
            ),
          );
    } catch (e) {
      // Close any open dialogs
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      setState(() => _submitted = false);
      AppToast.showError(context, 'فشل في رفع الصور: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return BlocProvider(
      create: (context) => ReportCompletionCubit(),
      child: BlocListener<ReportsBloc, ReportsState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (_submitted && state.status == ReportsStatus.success) {
            AppToast.showSuccess(context, 'تم إكمال البلاغ بنجاح');
            // Simply pop back to preserve navigation context
            context.pop();
          } else if (_submitted && state.status == ReportsStatus.failure) {
            AppToast.showError(
                context, state.errorMessage ?? 'حدث خطأ أثناء إكمال البلاغ');
          }
        },
        child: _ReportCompletionView(
          report: widget.report,
          onComplete: _handleCompletion,
        ),
      ),
    );
  }
}

class _ReportCompletionView extends StatelessWidget {
  final Report report;
  final void Function(ReportCompletionState, dynamic) onComplete;

  const _ReportCompletionView({
    required this.report,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: 'إكمال البلاغ',
          subtitle: 'تسجيل نتائج العمل المنجز',
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<ReportCompletionCubit, ReportCompletionState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.surfaceLight,
                        AppColors.cardBackground,
                      ],
                    ),
                  ),
                ),

                SingleChildScrollView(
                  padding: EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Completion Notes Section
                      _buildCompletionNotesCard(context, theme, state),

                      SizedBox(height: AppPadding.medium),

                      // Images Section
                      _buildImagesCard(context, theme, state),

                      SizedBox(height: AppPadding.large),

                      // Complete Button
                      _buildCompleteButton(context, state),

                      SizedBox(height: AppPadding.large),
                    ],
                  ),
                ),

                // Loading indicator
                if (context.watch<ReportsBloc>().state.status ==
                    ReportsStatus.loading)
                  const AppLoadingIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompletionNotesCard(
      BuildContext context, ThemeData theme, ReportCompletionState state) {
    final cubit = context.read<ReportCompletionCubit>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8)
                      ],
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
                  child: const Icon(
                    Icons.note_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppPadding.medium),
                Text(
                  'ملاحظات الإنجاز',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(AppPadding.medium),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText:
                      'اكتب ملاحظات مفصلة حول العمل المنجز والحلول المطبقة...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryDark.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppPadding.medium),
                ),
                maxLines: 5,
                textDirection: TextDirection.rtl,
                onChanged: cubit.completionNoteChanged,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard(
      BuildContext context, ThemeData theme, ReportCompletionState state) {
    final cubit = context.read<ReportCompletionCubit>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Padding(
            padding: EdgeInsets.all(AppPadding.medium),
            child: ImagePickerWidget(
              images: state.completionPhotos,
              onImagesChanged: cubit.completionPhotosChanged,
              // maxImages removed to use unlimited default
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(
      BuildContext context, ReportCompletionState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isValid
              ? [AppColors.primary, AppColors.primaryLight]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: state.isValid
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state.isValid ? () => onComplete(state, report) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(AppPadding.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (context.watch<ReportsBloc>().state.status ==
                    ReportsStatus.loading)
                  Container(
                    width: 24,
                    height: 24,
                    margin: EdgeInsets.only(left: AppPadding.small),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                SizedBox(width: AppPadding.small),
                Text(
                  'إكمال البلاغ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

/// Cubit for managing the report completion form state
class ReportCompletionCubit extends Cubit<ReportCompletionState> {
  ReportCompletionCubit() : super(const ReportCompletionState());

  void completionNoteChanged(String value) {
    emit(state.copyWith(
      completionNote: value,
      isValid: _validateForm(completionNote: value),
    ));
  }

  void completionPhotosChanged(List<String> photos) {
    emit(state.copyWith(
      completionPhotos: photos,
      isValid: _validateForm(completionPhotos: photos),
    ));
  }

  bool _validateForm({
    String? completionNote,
    List<String>? completionPhotos,
  }) {
    final note = completionNote ?? state.completionNote;
    final photos = completionPhotos ?? state.completionPhotos;

    // Validate that note is not empty and at least one photo is uploaded
    return note.isNotEmpty && photos.isNotEmpty;
  }
}

/// State for the report completion form
class ReportCompletionState extends Equatable {
  final String completionNote;
  final List<String> completionPhotos;
  final bool isValid;
  final String? errorMessage;

  const ReportCompletionState({
    this.completionNote = '',
    this.completionPhotos = const [],
    this.isValid = false,
    this.errorMessage,
  });

  ReportCompletionState copyWith({
    String? completionNote,
    List<String>? completionPhotos,
    bool? isValid,
    String? errorMessage,
  }) {
    return ReportCompletionState(
      completionNote: completionNote ?? this.completionNote,
      completionPhotos: completionPhotos ?? this.completionPhotos,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        completionNote,
        completionPhotos,
        isValid,
        errorMessage,
      ];
}
