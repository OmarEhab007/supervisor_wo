import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:ui';
import 'package:supervisor_wo/core/blocs/completion_rate/completion_rate.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

/// Screen that displays the completion rate statistics and charts
class CompletionRateScreen extends StatelessWidget {
  /// Creates a new CompletionRateScreen
  const CompletionRateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompletionRateBloc(
        reportRepository: RepositoryProvider.of<ReportRepository>(context),
      )..add(const CompletionRateStarted()),
      child: const CompletionRateView(),
    );
  }
}

/// The main view for the CompletionRateScreen
class CompletionRateView extends StatelessWidget {
  /// Creates a new CompletionRateView
  const CompletionRateView({super.key});

  @override
  Widget build(BuildContext context) {
   
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: 'معدل الإنجاز والإحصائيات',
          subtitle: 'تحليل الأداء',
          showRefreshButton: true,
          onRefresh: () => context.read<CompletionRateBloc>().add(const CompletionRateRefreshed()),
          isLoading: context.select<CompletionRateBloc, bool>(
            (bloc) => bloc.state.status == CompletionRateStatus.loading,
          ),
        ),
        body: BlocBuilder<CompletionRateBloc, CompletionRateState>(
          builder: (context, state) {
            final isLoading = state.status == CompletionRateStatus.initial ||
                state.status == CompletionRateStatus.loading;
            if (isLoading) {
              return Skeletonizer(
                enabled: isLoading,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernCompletionRateChart(context, state),
                      SizedBox(height: AppPadding.large),
                      _buildCombinedStatsContainer(context, state),
                    ],
                  ),
                ),
              );
            }

            if (state.status == CompletionRateStatus.failure) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'حدث خطأ أثناء تحميل البيانات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'خطأ غير معروف',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5BBA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            context.read<CompletionRateBloc>().add(
                                  const CompletionRateRefreshed(),
                                );
                          },
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CompletionRateBloc>().add(
                      const CompletionRateRefreshed(),
                    );
              },
              child: Skeletonizer(
                enabled: isLoading,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernCompletionRateChart(context, state),
                      SizedBox(height: AppPadding.large),
                      _buildCombinedStatsContainer(context, state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  /// Builds a modern header statistic item matching container design
  Widget _buildModernHeaderStat(
      String label, String value, IconData icon, Color accentColor, BuildContext context) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: AppSizes.blockHeight * 2.2,
            ),
          ),
          SizedBox(height: AppPadding.small),
          Text(
            value,
            style: theme.textTheme.displayMedium?.copyWith(
              color: accentColor,
              fontSize: AppSizes.blockHeight * 2.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppPadding.extraSmall),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryDark.withOpacity(0.8),
              fontSize: AppSizes.blockHeight * 1.4,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the modern completion rate chart with enhanced visuals
  Widget _buildModernCompletionRateChart(
    BuildContext context,
    CompletionRateState state,
  ) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    return Container(
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondaryLight.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  color: AppColors.secondary,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل توزيع البلاغات',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'عرض تفصيلي لحالة البلاغات',
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive dimensions
              final screenWidth = constraints.maxWidth;
              final isLargeScreen = screenWidth > 600;
              final isMediumScreen = screenWidth > 400;
              
              // Responsive chart radius and spacing
              final chartRadius = isLargeScreen ? 45.0 : (isMediumScreen ? 40.0 : 35.0);
              final centerRadius = isLargeScreen ? 40.0 : (isMediumScreen ? 35.0 : 30.0);
              final chartFlex = isLargeScreen ? 3 : 2;
              final legendFlex = isLargeScreen ? 2 : 2;
              
              return SizedBox(
                height: AppSizes.blockHeight * 20,
                child: Row(
                  children: [
                    Expanded(
                      flex: chartFlex,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: centerRadius,
                          borderData: FlBorderData(show: false),
                          sections: [
                            PieChartSectionData(
                              value: state.completedReports.toDouble(),
                              title: '',
                              color: AppColors.success,
                              radius: chartRadius,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: state.lateCompletedReports.toDouble(),
                              title: '',
                              color: AppColors.warning,
                              radius: chartRadius,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: state.lateReports.toDouble(),
                              title: '',
                              color: AppColors.error,
                              radius: chartRadius,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: state.pendingReports.toDouble(),
                              title: '',
                              color: AppColors.primary,
                              radius: chartRadius,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isLargeScreen ? AppPadding.large : AppPadding.medium),
                    Expanded(
                      flex: legendFlex,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModernLegendItem('مكتملة', AppColors.success,
                              state.completedReports, context),
                          _buildModernLegendItem('مكتملة متأخرة', AppColors.warning,
                              state.lateCompletedReports, context),
                          _buildModernLegendItem('متأخرة', AppColors.error,
                              state.lateReports, context),
                          _buildModernLegendItem('قيد الإنجاز', AppColors.primary,
                              state.pendingReports, context),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a combined container with both stats and insights sections
  Widget _buildCombinedStatsContainer(
    BuildContext context,
    CompletionRateState state,
  ) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    
    final totalReports = state.completedReports + state.lateCompletedReports + 
                        state.lateReports + state.pendingReports;
    final onTimeCompletion = totalReports > 0 
        ? (state.completedReports / totalReports * 100)
        : 0.0;
    
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
          // Header Stats Section
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondaryLight.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppColors.secondary,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإحصائيات العامة',
                      style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: AppSizes.blockHeight * 2.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.large),
          // Statistics Cards Row
          Row(
            children: [
              Expanded(
                child: _buildModernHeaderStat(
                  'معدل الإنجاز الكلي',
                  '${state.overallCompletionRate.toStringAsFixed(1)}%',
                  Icons.analytics_rounded,
                  AppColors.success,
                  context,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Container(
                height: 60,
                width: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: _buildModernHeaderStat(
                  'متوسط وقت الاستجابة',
                  '${state.averageResponseTime.toStringAsFixed(1)} ساعة',
                  Icons.schedule_rounded,
                  AppColors.warning,
                  context,
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.extraLarge),
          // Insights Section
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.secondaryLight.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: AppColors.secondary,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Text(
                'رؤى الأداء',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: AppSizes.blockHeight * 2.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.large),
          // Insights Cards Row
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  'الإنجاز في الوقت المحدد',
                  '${onTimeCompletion.toStringAsFixed(1)}%',
                  Icons.check_circle_rounded,
                  onTimeCompletion >= 80 ? AppColors.success : AppColors.warning,
                  context,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: _buildInsightCard(
                  'إجمالي البلاغات',
                  totalReports.toString(),
                  Icons.assignment_rounded,
                  AppColors.primary,
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a modern legend item for the chart
  Widget _buildModernLegendItem(
      String label, Color color, int value, BuildContext context) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppPadding.extraSmall * 0.5),
      padding: EdgeInsets.all(AppPadding.small * 0.9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: AppPadding.small),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppSizes.blockHeight * 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: AppPadding.extraSmall,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppSizes.blockHeight * 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Builds an insight card with modern styling
  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    AppSizes.init(context);
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: AppSizes.blockHeight * 2.2,
                ),
              ),
              SizedBox(width: AppPadding.small),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: AppSizes.blockHeight * 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.medium),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: AppSizes.blockHeight * 2.8,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
