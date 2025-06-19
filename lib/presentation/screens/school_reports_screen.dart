import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/presentation/widgets/report_card.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

/// Screen that displays all reports for a specific school
class SchoolReportsScreen extends StatefulWidget {
  final String schoolName;
  final ReportFilter? filter;

  const SchoolReportsScreen({
    super.key,
    required this.schoolName,
    this.filter,
  });

  @override
  State<SchoolReportsScreen> createState() => _SchoolReportsScreenState();
}

class _SchoolReportsScreenState extends State<SchoolReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Only refresh once when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsBloc>().add(const ReportsRefreshed());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: GradientAppBar(
          title: widget.schoolName,
          subtitle: 'بلاغات هذه المدرسة',
          automaticallyImplyLeading: false,
          showRefreshButton: true,
          onRefresh: () => context.read<ReportsBloc>().add(const ReportsRefreshed()),
          isLoading: context.select<ReportsBloc, bool>(
            (bloc) => bloc.state.status == ReportsStatus.loading,
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<ReportsBloc>().add(const ReportsRefreshed());
          },
          child: SafeArea(
            child: BlocBuilder<ReportsBloc, ReportsState>(
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

  Widget _buildReportsList(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);
    final isLoading = state.status == ReportsStatus.loading;

    // First get the reports based on the filter that was applied in the main reports screen
    List<Report> filteredReports;

    if (widget.filter != null) {
      // If a specific filter was provided, use the filteredReports from state
      // and then filter by school name
      filteredReports = state.reports.where((report) {
        switch (widget.filter) {
          case ReportFilter.all:
            return true;
          case ReportFilter.pending:
            return report.status.toLowerCase() == 'pending';
          case ReportFilter.completed:
            return report.status.toLowerCase() == 'completed';
          case ReportFilter.issues:
            return report.status == 'Issues';
          case ReportFilter.recent:
            final now = DateTime.now();
            final reportDate = report.scheduledDate;
            return reportDate.year == now.year &&
                reportDate.month == now.month &&
                reportDate.day == now.day;
          case ReportFilter.today:
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final scheduledDate = DateTime(
              report.scheduledDate.year,
              report.scheduledDate.month,
              report.scheduledDate.day,
            );
            return scheduledDate.isAtSameMomentAs(today) &&
                report.status != 'completed';
          case ReportFilter.late:
            return report.status.toLowerCase() == 'late';
          default:
            return true;
        }
      }).toList();
    } else {
      // When no filter is provided, use the same logic as in the main reports screen
      // Show only pending reports with scheduled dates of today, tomorrow, or after tomorrow
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final threeDaysLater =
          today.add(const Duration(days: 3)); // Today + 3 days

      filteredReports = state.reports.where((report) {
        // Check if report is pending
        if (report.status != 'pending') return false;

        // Check if scheduled date is today, tomorrow, or after tomorrow
        final scheduledDate = DateTime(
          report.scheduledDate.year,
          report.scheduledDate.month,
          report.scheduledDate.day,
        );

        return scheduledDate.compareTo(today) >= 0 &&
            scheduledDate.compareTo(threeDaysLater) < 0;
      }).toList();
    }

    // Then filter by school name
    List<Report> schoolReports = filteredReports
        .where((report) => report.schoolName == widget.schoolName)
        .toList();

    // Use placeholder data for skeleton loading when no reports are available
    final displayReports = schoolReports.isEmpty && isLoading
        ? _createPlaceholderReports()
        : schoolReports;

    // Only show empty state if not loading and no reports
    if (displayReports.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بلاغات لمدرسة ${widget.schoolName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppSizes.blockHeight * 2,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Wrap with Skeletonizer for loading effect
    return Skeletonizer(
      enabled: isLoading,
      // Customize the skeleton effect
      effect: ShimmerEffect(
        baseColor: theme.colorScheme.surface,
        highlightColor: theme.colorScheme.onSurface.withOpacity(0.1),
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayReports.length,
        padding: EdgeInsets.symmetric(
            vertical: AppSizes.blockHeight * 2,
            horizontal: AppSizes.blockWidth * 2),
        itemBuilder: (context, index) {
          final report = displayReports[index];

          return ReportCard(
            report: report,
          );
        },
      ),
    );
  }

  /// Creates placeholder reports for skeleton loading
  List<Report> _createPlaceholderReports() {
    // Create placeholder data for this school
    final now = DateTime.now();
    final placeholders = <Report>[];

    // Create 5 placeholder reports for this school
    for (int i = 1; i <= 5; i++) {
      placeholders.add(
        Report(
          id: 'placeholder-$i',
          schoolName: widget.schoolName,
          scheduledDate: now,
          priority: i % 2 == 0 ? 'Emergency' : 'Normal',
          status: 'Pending',
          description: 'وصف البلاغ',
          type: i % 3 == 0 ? 'Electricity' : 'Plumbing',
          images: const [],
          supervisorId: '1',
          supervisorName: 'المشرف',
          createdAt: now.subtract(Duration(days: i)),
          completionPhotos: const [],
        ),
      );
    }

    return placeholders;
  }
}
