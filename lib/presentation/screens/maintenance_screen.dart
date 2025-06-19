import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_bloc.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_event.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_state.dart';
import 'package:supervisor_wo/core/extensions/date_extensions.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/maintenance_report_model.dart';
import 'package:supervisor_wo/presentation/widgets/modern_maintenance_card.dart';
import 'package:supervisor_wo/presentation/widgets/maintenance_report_card.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

/// Screen that displays maintenance reports with tabs for pending and completed
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update tab appearance
      }
    });
    
    // Ensure the bloc is initialized when the screen is built
    context.read<MaintenanceBloc>().add(const MaintenanceStarted());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    AppSizes.init(context);

    return BlocListener<MaintenanceBloc, MaintenanceState>(
      listener: (context, state) {
        if (state.status == MaintenanceStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'حدث خطأ غير معروف'),
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
            title: 'الصيانات الدورية',
            subtitle: 'إدارة الصيانة',
            showRefreshButton: true,
            onRefresh: () => context.read<MaintenanceBloc>().add(const MaintenanceRefreshed()),
            isLoading: context.select<MaintenanceBloc, bool>(
              (bloc) => bloc.state.status == MaintenanceStatus.loading,
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
              context.read<MaintenanceBloc>().add(const MaintenanceRefreshed());
            },
            child: SafeArea(
              child: IndexedStack(
                index: _tabController.index,
                        children: [
                  _buildMaintenanceList('pending'),
                  _buildMaintenanceList('completed'),
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
                  'معلقة',
                  Icons.schedule_rounded,
                  AppColors.warning,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _buildTabOption(
                  1,
                  'مكتملة',
                  Icons.check_circle_rounded,
                  AppColors.success,
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
              AnimatedRotation(
                turns: isSelected ? 0.0 : -0.05,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  icon,
                  color: isSelected ? accentColor : Colors.white.withOpacity(0.8),
                  size: 20,
            ),
              ),
              SizedBox(width: 8),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? accentColor : Colors.white.withOpacity(0.9),
                    height: 1.2,
                  ),
              ),
            ),
          ],
        ),
        ),
      ),
      );
    }

  Widget _buildMaintenanceList(String filterType) {
    return BlocBuilder<MaintenanceBloc, MaintenanceState>(
      buildWhen: (previous, current) =>
          previous.reports != current.reports ||
          previous.status != current.status,
      builder: (context, state) {
        final isLoading = state.status == MaintenanceStatus.loading;

        // Filter reports based on the tab
        final filteredReports = state.reports.where((report) {
          if (filterType == 'pending') {
            return report.status == 'pending';
          } else {
            return report.status == 'completed';
          }
        }).toList();

        // Use placeholder data for skeleton loading when no reports are available
        final displayReports = filteredReports.isEmpty && isLoading
            ? _createPlaceholderReports()
            : filteredReports;

        // Show loading or empty state
        if (state.status == MaintenanceStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == MaintenanceStatus.failure) {
          return _buildErrorState(context);
        }

        return Skeletonizer(
          enabled: isLoading,
          child: displayReports.isEmpty && !isLoading
              ? _buildEmptyState(context, filterType)
              : filterType == 'pending'
                  ? _buildPendingMaintenanceList(context, displayReports, isLoading)
                  : _buildCompletedMaintenanceList(context, displayReports, isLoading),
        );
      },
    );
  }

  Widget _buildPendingMaintenanceList(BuildContext context, List<MaintenanceReport> reports, bool isLoading) {
    final theme = Theme.of(context);

    // Group reports by scheduled date category (today, tomorrow, after tomorrow)
    final groupedByDate = <String, List<MaintenanceReport>>{};

    for (final report in reports) {
      // Use createdAt as the date for grouping
      final dateCategory = report.createdAt.dateCategory;
      if (!groupedByDate.containsKey(dateCategory)) {
        groupedByDate[dateCategory] = [];
      }
      groupedByDate[dateCategory]!.add(report);
    }

    // Further group reports by school within each date category
    final groupedByDateAndSchool = <String, Map<String, List<MaintenanceReport>>>{};

    for (final entry in groupedByDate.entries) {
      final dateCategory = entry.key;
      final dateReports = entry.value;

      // Initialize the map for this date category
      groupedByDateAndSchool[dateCategory] = {};

      // Group reports by school ID
      for (final report in dateReports) {
        final schoolId = report.schoolId;
        if (!groupedByDateAndSchool[dateCategory]!.containsKey(schoolId)) {
          groupedByDateAndSchool[dateCategory]![schoolId] = [];
        }
        groupedByDateAndSchool[dateCategory]![schoolId]!.add(report);
      }
    }

    // Sort the date categories to ensure today comes first, then tomorrow, etc.
    final sortedCategories = groupedByDate.keys.toList()
      ..sort((a, b) {
        if (a == 'اليوم') return -1;
        if (b == 'اليوم') return 1;
        if (a == 'غداً') return -1;
        if (b == 'غداً') return 1;
        if (a == 'بعد غد') return -1;
        if (b == 'بعد غد') return 1;
        return a.compareTo(b);
      });

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.medium),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
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
          mainAxisSize: MainAxisSize.min,
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
                        AppColors.warning.withOpacity(0.1),
                        AppColors.warning.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.build_rounded,
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
                        'الصيانات المعلقة',
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
            ...sortedCategories.map((category) {
              final schoolsMap = groupedByDateAndSchool[category]!;
              final schoolNames = schoolsMap.keys.toList();

              return Padding(
                padding: EdgeInsets.only(bottom: AppPadding.large),
                child: Column(
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
                                  '${schoolsMap.values.fold(0, (sum, reports) => sum + reports.length)} صيانة دورية • ${schoolsMap.length} مدرسة',
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
                    ...schoolNames.map((schoolId) {
                      final schoolReports = schoolsMap[schoolId]!;
                      final schoolName = schoolReports.first.schoolId;

                      return Padding(
                        padding: EdgeInsets.only(bottom: AppPadding.small),
                        child: buildModernMaintenanceCard(
                          context,
                          schoolName,
                          schoolReports.length,
                          onTap: () {
                            context.push('/school-maintenance/$schoolId',
                                extra: {'schoolName': schoolName});
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedMaintenanceList(BuildContext context, List<MaintenanceReport> reports, bool isLoading) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.medium),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
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
          mainAxisSize: MainAxisSize.min,
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
                        'الصيانات المكتملة',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: AppSizes.blockHeight * 2.4,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'قائمة بجميع الصيانات المنجزة',
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
            ...reports.asMap().entries.map((entry) {
              final index = entry.key;
              final report = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < reports.length - 1 ? AppPadding.medium : 0,
                ),
                child: MaintenanceReportCard(report: report),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filterType) {
    final theme = Theme.of(context);
    final isPending = filterType == 'pending';

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.medium),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: (isPending ? AppColors.warning : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
                size: AppSizes.blockHeight * 8,
                color: isPending ? AppColors.warning : AppColors.success,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              isPending ? 'لا توجد صيانات معلقة' : 'لا توجد صيانات مكتملة',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              isPending 
                  ? 'سيتم عرض الصيانات المعلقة هنا عند إضافتها'
                  : 'سيتم عرض الصيانات المكتملة هنا عند إنجازها',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark.withOpacity(0.7),
                fontSize: AppSizes.blockHeight * 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'حدث خطأ أثناء تحميل البيانات',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<MaintenanceBloc>().add(const MaintenanceStarted());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  List<MaintenanceReport> _createPlaceholderReports() {
    final now = DateTime.now();
    final placeholders = <MaintenanceReport>[];

    // Create 3 placeholder reports with varied data
    for (int i = 0; i < 3; i++) {
      placeholders.add(
      MaintenanceReport(
          id: 'placeholder-$i',
        supervisorId: '1',
          schoolId: 'school-$i',
          description: 'وصف صيانة دورية',
        status: 'pending',
        images: const [],
          createdAt: now.subtract(Duration(days: i)),
        completionPhotos: const [],
      ),
      );
    }

    // Add some completed ones
    for (int i = 3; i < 6; i++) {
      placeholders.add(
      MaintenanceReport(
          id: 'placeholder-$i',
        supervisorId: '1',
          schoolId: 'school-$i',
          description: 'وصف صيانة دورية مكتملة',
        status: 'completed',
        images: const [],
          createdAt: now.subtract(Duration(days: i)),
        completionPhotos: const [],
          completionNote: 'تمت الصيانة بنجاح',
          closedAt: now.subtract(Duration(days: i - 1)),
      ),
      );
    }

    return placeholders;
  }
}
