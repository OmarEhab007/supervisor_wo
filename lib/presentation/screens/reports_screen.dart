import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:ui';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/extensions/date_extensions.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/utils/placeholder_utils.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/report_model.dart';

import '../widgets/modern_school_card.dart';
import '../widgets/report_card.dart';
import '../widgets/gradient_app_bar.dart';

/// Screen that displays all reports for the supervisor
class ReportsScreen extends StatelessWidget {
  final ReportFilter? filter;

  const ReportsScreen({super.key, this.filter});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);

    // Apply the filter if provided, or reset to all if no filter
    if (filter != null) {
      // Set the filter in the BLoC
      context.read<ReportsBloc>().add(ReportsFilterChanged(filter!));
    } else {
      // Reset to all reports when no filter is specified
      context
          .read<ReportsBloc>()
          .add(const ReportsFilterChanged(ReportFilter.all));
    }

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
            title: _getScreenTitle(),
            subtitle: 'إدارة البلاغات',
            showRefreshButton: true,
            onRefresh: () =>
                context.read<ReportsBloc>().add(const ReportsRefreshed()),
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
                    previous.filteredReports != current.filteredReports ||
                    previous.status != current.status,
                builder: (context, state) {
                  final isLoading = state.status == ReportsStatus.loading;
                  return Skeletonizer(
                    enabled: isLoading,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppPadding.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernStatsSection(context, state),
                          SizedBox(height: AppPadding.large),
                          _buildModernReportsList(context, state),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a compact and clean stats header
  Widget _buildModernStatsSection(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);
    AppSizes.init(context);

    // Calculate statistics based on current filter
    List<Report> reportsToShow =
        filter == null ? state.upcomingReports : state.filteredReports;
    final totalReports = reportsToShow.length;
    final emergencyReports =
        reportsToShow.where((r) => r.priority == 'Emergency').length;
    final schoolsCount = reportsToShow.map((r) => r.schoolName).toSet().length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primary,
                  size: AppSizes.blockHeight * 2.0,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص البلاغات',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'نظرة سريعة على الإحصائيات',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 1.6,
                        color: AppColors.primaryDark.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.medium),
          // Compact Stats Row
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactStat(
                    totalReports.toString(),
                    'إجمالي البلاغات',
                    Icons.assignment_rounded,
                    AppColors.primary,
                    context,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.primary.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildCompactStat(
                    emergencyReports.toString(),
                    'حالات طوارئ',
                    Icons.warning_rounded,
                    emergencyReports > 0 ? AppColors.error : AppColors.success,
                    context,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: AppColors.primary.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildCompactStat(
                    schoolsCount.toString(),
                    'المدارس',
                    Icons.school_rounded,
                    AppColors.secondary,
                    context,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the modern reports list
  Widget _buildModernReportsList(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);
    final isLoading = state.status == ReportsStatus.loading;

    // Use appropriate filtered data based on the filter parameter
    List<Report> reportsToShow;

    if (filter == null) {
      // When accessed from the main reports button, use pre-computed upcoming reports
      reportsToShow = state.upcomingReports;
    } else {
      // Use the state's pre-computed filteredReports from the BLoC
      reportsToShow = state.filteredReports;
    }

    // --- EMPTY STATE UI ---
    if (!isLoading && reportsToShow.isEmpty) {
      return Container(
        width: double.infinity,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/images/mechanic.png',
                height: AppSizes.blockHeight * 8,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'لا توجد بلاغات حالياً',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'سيتم عرض البلاغات هنا عند إضافتها',
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

    // Use safe placeholder data management
    final filteredReports = PlaceholderUtils.shouldUsePlaceholders(
      isLoading: isLoading,
      reports: reportsToShow,
    )
        ? PlaceholderUtils.createPlaceholderReports(
            isLoading: isLoading,
            hasRealData: reportsToShow.isNotEmpty,
          )
        : reportsToShow;

    // If the filter is completed, show a modern flat list (no grouping by date)
    if (filter == ReportFilter.completed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppPadding.large),
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
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.1),
                        AppColors.success.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: AppSizes.blockHeight * 2.4,
                  ),
                ),
                SizedBox(width: AppPadding.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'البلاغات المنجزة',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: AppSizes.blockHeight * 2.4,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'قائمة بجميع البلاغات المكتملة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: AppSizes.blockHeight * 1.6,
                          color: AppColors.primaryDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppPadding.large),
            // Reports List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredReports.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppPadding.medium),
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return ReportCard(report: report);
              },
            ),
          ],
        ),
      );
    }

    // Group reports by scheduled date category (today, tomorrow, after tomorrow)
    final groupedReports = <String, List<Report>>{};

    for (final report in filteredReports) {
      final dateCategory = report.scheduledDate.dateCategory;
      if (!groupedReports.containsKey(dateCategory)) {
        groupedReports[dateCategory] = [];
      }
      groupedReports[dateCategory]!.add(report);
    }

    // Further group reports by school within each date category
    final groupedBySchool = <String, Map<String, List<Report>>>{};

    for (final entry in groupedReports.entries) {
      final dateCategory = entry.key;
      final reports = entry.value;

      // Initialize the map for this date category
      groupedBySchool[dateCategory] = {};

      // Group reports by school name
      for (final report in reports) {
        final schoolName = report.schoolName;
        if (!groupedBySchool[dateCategory]!.containsKey(schoolName)) {
          groupedBySchool[dateCategory]![schoolName] = [];
        }
        groupedBySchool[dateCategory]![schoolName]!.add(report);
      }
    }

    // Sort the date categories to ensure today comes first, then tomorrow, etc.
    final sortedCategories = groupedReports.keys.toList()
      ..sort((a, b) {
        if (a == 'اليوم') return -1;
        if (b == 'اليوم') return 1;
        if (a == 'غداً') return -1;
        if (b == 'غداً') return 1;
        if (a == 'بعد غد') return -1;
        if (b == 'بعد غد') return 1;
        return a.compareTo(b);
      });

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.large),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primaryLight.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البلاغات المجدولة',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'مجمعة حسب التاريخ والمدرسة',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 1.6,
                        color: AppColors.primaryDark.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.large),
          // Date Categories List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: AppPadding.large),
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final schoolsMap = groupedBySchool[category]!;
              final schoolNames = schoolsMap.keys.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimal Date category header
                  Container(
                    margin: EdgeInsets.only(bottom: AppPadding.medium),
                    child: Row(
                      children: [
                        // Simple line indicator
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.secondary,
                                AppColors.secondaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: AppPadding.medium),
                        // Date text and stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff1E293B),
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${schoolsMap.values.fold(0, (sum, reports) => sum + reports.length)} بلاغ • ${schoolsMap.length} مدرسة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Minimal date badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppPadding.medium),
                  // Schools for this category
                  ...schoolNames.map((schoolName) {
                    final schoolReports = schoolsMap[schoolName]!;
                    final hasEmergency = schoolReports
                        .any((report) => report.priority == 'Emergency');

                    return Padding(
                      padding: EdgeInsets.only(bottom: AppPadding.medium),
                      child: buildModernSchoolCard(
                        context,
                        schoolName,
                        schoolReports.length,
                        hasEmergency,
                        Theme.of(context).colorScheme,
                        onTap: () {
                          // Navigate to school reports screen with both school name and current filter
                          final currentState =
                              context.read<ReportsBloc>().state;
                          final Map<String, dynamic> extraData = {
                            'schoolName': schoolName,
                            'filter': currentState.activeFilter,
                          };
                          context.push('/school-reports', extra: extraData);
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a compact stat item for the stats row
  Widget _buildCompactStat(
    String value,
    String label,
    IconData icon,
    Color accentColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(AppPadding.small * 0.8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: AppSizes.blockHeight * 1.8,
          ),
        ),
        SizedBox(height: AppPadding.small),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: accentColor,
            fontSize: AppSizes.blockHeight * 2.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppPadding.extraSmall * 0.5),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryDark.withOpacity(0.7),
            fontSize: AppSizes.blockHeight * 1.2,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Get the screen title based on the filter
  String _getScreenTitle() {
    if (filter == null) {
      return 'جميع البلاغات'; // 'Upcoming Reports'
    }

    switch (filter) {
      case ReportFilter.today:
        return 'بلاغات اليوم';
      case ReportFilter.completed:
        return 'البلاغات المنجزة';
      case ReportFilter.lateCompleted:
        return 'البلاغات المنجزة المتأخرة';
      case ReportFilter.late:
        return 'البلاغات المتأخرة';
      default:
        return 'البلاغات';
    }
  }
}
