import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/presentation/widgets/report_card.dart';
import 'package:supervisor_wo/presentation/widgets/modern_school_card.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

import '../../core/services/theme.dart';

/// Screen that displays only late reports for the supervisor
class LateReportsScreen extends StatefulWidget {
  const LateReportsScreen({super.key});

  @override
  State<LateReportsScreen> createState() => _LateReportsScreenState();
}

class _LateReportsScreenState extends State<LateReportsScreen> {
  // Pagination variables
  static const int _reportsPerPage = 20;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
   
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state.status == ReportsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: GradientAppBar(
            title: 'البلاغات المتأخرة',
            subtitle: 'إدارة البلاغات',
            showRefreshButton: true,
            onRefresh: () {
              context.read<ReportsBloc>().add(const ReportsRefreshed());
              context.read<ReportsBloc>().add(const ReportsCheckLateStatus());
              // Reset pagination on refresh
              setState(() => _currentPage = 1);
            },
            isLoading: context.select<ReportsBloc, bool>(
              (bloc) => bloc.state.status == ReportsStatus.loading,
            ),
            actions: [
              // Force Late Check Button
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.update,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Force an immediate check for late reports
                    context
                        .read<ReportsBloc>()
                        .add(const ReportsCheckLateStatus());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث حالة البلاغات المتأخرة'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    // Reset pagination after update
                    setState(() => _currentPage = 1);
                  },
                  tooltip: 'تحديث حالة البلاغات المتأخرة',
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ReportsBloc>().add(const ReportsRefreshed());
              // Also check for late reports after refreshing
              context.read<ReportsBloc>().add(const ReportsCheckLateStatus());
              // Reset pagination on refresh
              setState(() => _currentPage = 1);
            },
            child: SafeArea(
              child: BlocBuilder<ReportsBloc, ReportsState>(
                buildWhen: (previous, current) =>
                    previous.reports != current.reports ||
                    previous.status != current.status,
                builder: (context, state) {
                  return _buildLateReportsList(context, state);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLateReportsList(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);
    final isLoading = state.status == ReportsStatus.loading;

    // Filter only late reports
    final allLateReports =
        state.reports.where((report) => report.status == 'late').toList();

    // Calculate pagination
    final totalReports = allLateReports.length;
    final totalPages = (totalReports / _reportsPerPage).ceil();
    
    // Get reports for current page
    final startIndex = (_currentPage - 1) * _reportsPerPage;
    final endIndex = (startIndex + _reportsPerPage).clamp(0, totalReports);
    final paginatedReports = totalReports > 0 
        ? allLateReports.sublist(startIndex, endIndex)
        : <Report>[];

    // If we're loading and have no reports, create some placeholder data
    final reportsToShow = isLoading && paginatedReports.isEmpty
        ? _createPlaceholderLateReports()
        : paginatedReports;

    // Show empty state if no late reports
    if (allLateReports.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بلاغات متأخرة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع البلاغات في الوقت المحدد',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats header
        if (!isLoading && totalReports > 0) 
          _buildStatsHeader(totalReports, reportsToShow.length),
        
        // Reports list
        Expanded(
          child: Skeletonizer(
            enabled: isLoading,
            effect: ShimmerEffect(
              baseColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              highlightColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            child: _buildReportsListView(reportsToShow),
          ),
        ),
        
        // Pagination controls
        if (totalPages > 1 && !isLoading)
          _buildPaginationControls(_currentPage, totalPages),
      ],
    );
  }

  Widget _buildStatsHeader(int totalReports, int currentPageReports) {
    return Container(
      margin: EdgeInsets.all(AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.schedule,
              color: AppColors.warning,
              size: AppSizes.blockHeight * 2.4,
            ),
          ),
          SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البلاغات المتأخرة',
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * 2.4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  'عرض $currentPageReports من أصل $totalReports بلاغ متأخر',
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * 1.6,
                    color: AppColors.primaryDark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsListView(List<Report> reportsToShow) {
    // Group reports by school
    final groupedBySchool = <String, List<Report>>{};

    for (final report in reportsToShow) {
      final schoolName = report.schoolName;
      if (!groupedBySchool.containsKey(schoolName)) {
        groupedBySchool[schoolName] = [];
      }
      groupedBySchool[schoolName]!.add(report);
    }

    // Sort schools alphabetically
    final sortedSchools = groupedBySchool.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSchools.length,
      itemBuilder: (context, index) {
        final schoolName = sortedSchools[index];
        final schoolReports = groupedBySchool[schoolName]!;
        final hasEmergency =
            schoolReports.any((report) => report.priority == 'Emergency');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // School header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: buildModernSchoolCard(
                context,
                schoolName,
                schoolReports.length,
                hasEmergency,
                Theme.of(context).colorScheme,
                onTap: () {
                  // Navigate to school reports screen with the school name
                },
                color: Colors.orange, // Use orange for late reports
              ),
            ),
            // Reports for this school
            ...schoolReports.map((report) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 12, right: 16, left: 16),
                  child: ReportCard(report: report),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Build pagination controls
  Widget _buildPaginationControls(int currentPage, int totalPages) {
    return Container(
      margin: EdgeInsets.all(AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.warning.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Pagination info
          Text(
            'الصفحة $currentPage من $totalPages',
            style: TextStyle(
              fontSize: AppSizes.blockHeight * 1.8,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.medium),
          // Pagination buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _buildPaginationButton(
                icon: Icons.arrow_back_ios_rounded,
                label: 'السابق',
                isEnabled: currentPage > 1,
                onTap: currentPage > 1 
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentPage--);
                      }
                    : null,
              ),
              SizedBox(width: AppPadding.medium),
              // Page numbers (show up to 5 pages)
              ..._buildPageNumbers(currentPage, totalPages),
              SizedBox(width: AppPadding.medium),
              // Next button
              _buildPaginationButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'التالي',
                isEnabled: currentPage < totalPages,
                onTap: currentPage < totalPages 
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentPage++);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build pagination button
  Widget _buildPaginationButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.small,
          ),
          decoration: BoxDecoration(
            color: isEnabled 
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.primaryDark.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                  ? AppColors.warning.withOpacity(0.3)
                  : AppColors.primaryDark.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isEnabled 
                    ? AppColors.warning
                    : AppColors.primaryDark.withOpacity(0.4),
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEnabled 
                      ? AppColors.warning
                      : AppColors.primaryDark.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build page number buttons
  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> pageButtons = [];
    
    // Calculate which pages to show (max 5 pages)
    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = (startPage + 4).clamp(1, totalPages);
    
    // Adjust start page if we're near the end
    if (endPage == totalPages) {
      startPage = (totalPages - 4).clamp(1, totalPages);
    }

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _currentPage = i);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: i == currentPage 
                    ? AppColors.warning
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == currentPage 
                      ? AppColors.warning
                      : AppColors.primaryDark.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: i == currentPage 
                        ? Colors.white
                        : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      if (i < endPage) {
        pageButtons.add(SizedBox(width: 8));
      }
    }

    return pageButtons;
  }

  /// Creates placeholder late reports for skeleton loading
  List<Report> _createPlaceholderLateReports() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 2));

    return [
      Report(
        id: '1',
        schoolName: 'مدرسة الأمل',
        scheduledDate: yesterday,
        priority: 'Normal',
        status: 'late',
        description: 'صيانة مكيف الهواء في الفصل 101',
        type: 'AC',
        images: const [],
        supervisorId: '1',
        supervisorName: 'المشرف',
        createdAt: yesterday.subtract(const Duration(days: 1)),
        completionPhotos: const [],
      ),
      Report(
        id: '2',
        schoolName: 'مدرسة النور',
        scheduledDate: yesterday,
        priority: 'Emergency',
        status: 'late',
        description: 'تسرب مياه في دورة المياه',
        type: 'Plumbing',
        images: const [],
        supervisorId: '1',
        supervisorName: 'المشرف',
        createdAt: yesterday.subtract(const Duration(days: 1)),
        completionPhotos: const [],
      ),
    ];
  }
}
