import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/utils/placeholder_utils.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/report_model.dart';
import 'package:supervisor_wo/presentation/widgets/report_card.dart';

import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

/// Screen that displays completed reports with tabs for completed and late completed
class CompletedReportsScreen extends StatefulWidget {
  const CompletedReportsScreen({super.key});

  @override
  State<CompletedReportsScreen> createState() => _CompletedReportsScreenState();
}

class _CompletedReportsScreenState extends State<CompletedReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Pagination variables
  static const int _reportsPerPage = 20;
  int _completedCurrentPage = 1;
  int _lateCompletedCurrentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update tab appearance
        // Reset pagination when switching tabs
        if (_tabController.index == 0) {
          _completedCurrentPage = 1;
        } else {
          _lateCompletedCurrentPage = 1;
        }
      }
    });
    
    // Load completed reports by default
    context.read<ReportsBloc>().add(const ReportsFilterChanged(ReportFilter.completed));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get current page number based on active filter
  int get _currentPage {
    return _tabController.index == 0 ? _completedCurrentPage : _lateCompletedCurrentPage;
  }

  /// Set current page number based on active filter
  void _setCurrentPage(int page) {
    setState(() {
      if (_tabController.index == 0) {
        _completedCurrentPage = page;
      } else {
        _lateCompletedCurrentPage = page;
      }
    });
  }

  /// Reset pagination when switching tabs
  void _resetPagination() {
    setState(() {
      _completedCurrentPage = 1;
      _lateCompletedCurrentPage = 1;
    });
  }

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
            title: 'البلاغات المنجزة',
            subtitle: 'إدارة البلاغات',
            showRefreshButton: true,
            onRefresh: () => context.read<ReportsBloc>().add(const ReportsRefreshed()),
            isLoading: context.select<ReportsBloc, bool>(
              (bloc) => bloc.state.status == ReportsStatus.loading,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72.0),
              child: Container(
                margin: EdgeInsets.fromLTRB(AppPadding.large, 0, AppPadding.large, AppPadding.medium),
                child: _buildModernTabSelector(),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ReportsBloc>().add(const ReportsRefreshed());
            },
            child: SafeArea(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildReportsList(ReportFilter.completed),
                  _buildReportsList(ReportFilter.lateCompleted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a modern, clean tab selector with enhanced design
  Widget _buildModernTabSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTabOption(
                  0,
                  'مكتملة',
                  Icons.check_circle_rounded,
                  AppColors.success,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _buildTabOption(
                  1,
                  'مكتملة متأخرة',
                  Icons.schedule_rounded,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds individual tab option with modern styling and micro-interactions
  Widget _buildTabOption(int index, String title, IconData icon, Color accentColor) {
    final isSelected = _tabController.index == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_tabController.index != index) {
            // Add haptic feedback for better UX
            HapticFeedback.lightImpact();
            _tabController.animateTo(index);
            final filter = index == 0 ? ReportFilter.completed : ReportFilter.lateCompleted;
            context.read<ReportsBloc>().add(ReportsFilterChanged(filter));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? accentColor.withOpacity(0.12)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(isSelected ? 10 : 8),
                ),
                child: AnimatedRotation(
                  turns: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 350),
                  child: Icon(
                    icon,
                    size: AppSizes.blockHeight * (isSelected ? 2.0 : 1.8),
                    color: isSelected ? accentColor : Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(width: AppPadding.small),
              // Animated text
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontSize: AppSizes.blockHeight * (isSelected ? 1.6 : 1.4),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : Colors.white.withOpacity(0.9),
                    letterSpacing: isSelected ? 0.5 : 0.0,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(ReportFilter filter) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      buildWhen: (previous, current) =>
          previous.filteredReports != current.filteredReports ||
          previous.status != current.status ||
          previous.activeFilter != current.activeFilter,
      builder: (context, state) {
        final isLoading = state.status == ReportsStatus.loading;
        
        // Get reports based on the filter
        List<Report> allReports;
        if (state.activeFilter == filter) {
          allReports = state.filteredReports;
        } else {
          // Filter manually if not current filter
          allReports = state.reports
              .where((report) => filter == ReportFilter.completed 
                  ? report.status == 'completed'
                  : report.status == 'late_completed')
              .toList();
        }

        // Calculate pagination
        final totalReports = allReports.length;
        final totalPages = (totalReports / _reportsPerPage).ceil();
        final currentPage = filter == ReportFilter.completed ? _completedCurrentPage : _lateCompletedCurrentPage;
        
        // Get reports for current page
        final startIndex = (currentPage - 1) * _reportsPerPage;
        final endIndex = (startIndex + _reportsPerPage).clamp(0, totalReports);
        final paginatedReports = totalReports > 0 
            ? allReports.sublist(startIndex, endIndex)
            : <Report>[];

        return Skeletonizer(
          enabled: isLoading,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(AppPadding.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(context, allReports, filter),
                SizedBox(height: AppPadding.large),
                _buildReportsContainer(context, paginatedReports, filter, isLoading, totalReports),
                if (totalPages > 1 && !isLoading) ...[
                  SizedBox(height: AppPadding.large),
                  _buildPaginationControls(currentPage, totalPages, filter),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context, List<Report> reports, ReportFilter filter) {
    final theme = Theme.of(context);
    final isLateCompleted = filter == ReportFilter.lateCompleted;
    final totalReports = reports.length;
    final emergencyReports = reports.where((r) => r.priority == 'Emergency').length;
    final schoolsCount = reports.map((r) => r.schoolName).toSet().length;
    
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
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: isLateCompleted 
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLateCompleted ? Icons.schedule : Icons.check_circle,
                  color: isLateCompleted ? AppColors.warning : AppColors.success,
                  size: AppSizes.blockHeight * 2.0,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLateCompleted ? 'البلاغات المكتملة المتأخرة' : 'البلاغات المكتملة',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      isLateCompleted 
                          ? 'البلاغات التي تم إكمالها بعد الموعد المحدد'
                          : 'البلاغات التي تم إكمالها في الوقت المحدد',
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
          // Stats Row
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
                    isLateCompleted ? AppColors.warning : AppColors.success,
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

  Widget _buildReportsContainer(BuildContext context, List<Report> reports, ReportFilter filter, bool isLoading, int totalReports) {
    final theme = Theme.of(context);
    final isLateCompleted = filter == ReportFilter.lateCompleted;

    // Use safe placeholder data management
    final filteredReports = PlaceholderUtils.shouldUsePlaceholders(
      isLoading: isLoading,
      reports: reports,
    )
        ? PlaceholderUtils.createPlaceholderReports(
            isLoading: isLoading,
            hasRealData: reports.isNotEmpty,
          )
        : reports;

    // Empty state
    if (!isLoading && filteredReports.isEmpty) {
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
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: (isLateCompleted ? AppColors.warning : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isLateCompleted ? Icons.schedule : Icons.check_circle,
                size: AppSizes.blockHeight * 8,
                color: isLateCompleted ? AppColors.warning : AppColors.success,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              isLateCompleted ? 'لا توجد بلاغات مكتملة متأخرة' : 'لا توجد بلاغات مكتملة',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              isLateCompleted 
                  ? 'لم يتم إكمال أي بلاغات بعد الموعد المحدد'
                  : 'لم يتم إكمال أي بلاغات حتى الآن',
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with pagination info
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isLateCompleted ? AppColors.warning : AppColors.success).withOpacity(0.1),
                      (isLateCompleted ? AppColors.warning : AppColors.success).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLateCompleted ? Icons.schedule : Icons.check_circle_rounded,
                  color: isLateCompleted ? AppColors.warning : AppColors.success,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLateCompleted ? 'البلاغات المكتملة المتأخرة' : 'البلاغات المكتملة',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'عرض ${reports.length} من أصل $totalReports بلاغ',
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
            separatorBuilder: (context, index) => SizedBox(height: AppPadding.medium),
            itemBuilder: (context, index) {
              final report = filteredReports[index];
              return ReportCard(report: report);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    String value,
    String label,
    IconData icon,
    Color accentColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Build pagination controls
  Widget _buildPaginationControls(int currentPage, int totalPages, ReportFilter filter) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
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
                        if (filter == ReportFilter.completed) {
                          _setCurrentPage(_completedCurrentPage - 1);
                        } else {
                          _setCurrentPage(_lateCompletedCurrentPage - 1);
                        }
                      }
                    : null,
              ),
              SizedBox(width: AppPadding.medium),
              // Page numbers (show up to 5 pages)
              ..._buildPageNumbers(currentPage, totalPages, filter),
              SizedBox(width: AppPadding.medium),
              // Next button
              _buildPaginationButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'التالي',
                isEnabled: currentPage < totalPages,
                onTap: currentPage < totalPages 
                    ? () {
                        HapticFeedback.lightImpact();
                        if (filter == ReportFilter.completed) {
                          _setCurrentPage(_completedCurrentPage + 1);
                        } else {
                          _setCurrentPage(_lateCompletedCurrentPage + 1);
                        }
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
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.primaryDark.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                  ? AppColors.primary.withOpacity(0.3)
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
                    ? AppColors.primary
                    : AppColors.primaryDark.withOpacity(0.4),
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEnabled 
                      ? AppColors.primary
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
  List<Widget> _buildPageNumbers(int currentPage, int totalPages, ReportFilter filter) {
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
              if (filter == ReportFilter.completed) {
                setState(() => _completedCurrentPage = i);
              } else {
                setState(() => _lateCompletedCurrentPage = i);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: i == currentPage 
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == currentPage 
                      ? AppColors.primary
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
} 