import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_bloc.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_event.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/presentation/widgets/maintenance_report_card.dart';

/// Screen that displays all maintenance reports for a specific school
class SchoolMaintenanceReportsScreen extends StatelessWidget {
  final String schoolId;
  final String? schoolName;

  const SchoolMaintenanceReportsScreen({
    super.key,
    required this.schoolId,
    this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: schoolName ?? 'تقارير الصيانة',
          subtitle: 'إدارة صيانة المدرسة',
          showRefreshButton: true,
          onRefresh: () => context.read<MaintenanceBloc>().add(const MaintenanceRefreshed()),
          isLoading: context.select<MaintenanceBloc, bool>(
            (bloc) => bloc.state.status == MaintenanceStatus.loading,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<MaintenanceBloc>().add(const MaintenanceRefreshed());
          },
          child: SafeArea(
            child: BlocBuilder<MaintenanceBloc, MaintenanceState>(
              buildWhen: (previous, current) =>
                  previous.reports != current.reports ||
                  previous.status != current.status,
              builder: (context, state) {
                return _buildReportsList(context, state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, MaintenanceState state) {
    final theme = Theme.of(context);
    final isLoading = state.status == MaintenanceStatus.loading;

    // Filter maintenance reports for this school
    final schoolReports =
        state.reports.where((report) => report.schoolId == schoolId).toList();

    // Use placeholder data for skeleton loading when no reports are available
    final displayReports = schoolReports.isEmpty && isLoading
        ? _createPlaceholderReports()
        : schoolReports;

    // Only show empty state if not loading and no reports
    if (displayReports.isEmpty && !isLoading) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(AppPadding.medium),
        padding: EdgeInsets.all(AppPadding.extraLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.build_rounded,
                size: AppSizes.blockHeight * 8,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'لا توجد صيانات دورية',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'لا توجد صيانات دورية مسجلة لهذه المدرسة حالياً',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark.withOpacity(0.7),
                fontSize: AppSizes.blockHeight * 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Wrap with Skeletonizer for loading effect
    return Skeletonizer(
      enabled: isLoading,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayReports.length,
        padding: EdgeInsets.all(AppPadding.medium),
        itemBuilder: (context, index) {
          final report = displayReports[index];
          return Padding(
            padding: EdgeInsets.only(bottom: AppPadding.medium),
            child: MaintenanceReportCard(
              report: report,
            ),
          );
        },
      ),
    );
  }

  /// Creates placeholder maintenance reports for skeleton loading
  List<MaintenanceReport> _createPlaceholderReports() {
    final now = DateTime.now();
    return List.generate(
        5,
        (i) => MaintenanceReport(
              id: 'placeholder-$i',
              supervisorId: '1',
              schoolId: schoolId,
              description: 'وصف صيانة دورية',
              status: 'pending',
              images: const [],
              createdAt: now.subtract(Duration(days: i)),
              completionPhotos: const [],
            ));
  }
}
