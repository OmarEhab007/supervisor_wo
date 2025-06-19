import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_sizes.dart';
import '../../core/services/theme.dart';

/// Modern overview dashboard widget with admin panel design
class OverviewDashboard extends StatelessWidget {
  final Map<String, int> stats;
  final bool isLoading;

  const OverviewDashboard({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminTheme = theme.extension<AdminPanelTheme>();
    AppSizes.init(context);

    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      child: _buildStatsGrid(theme, adminTheme),
    );
  }


  Widget _buildStatsGrid(ThemeData theme, AdminPanelTheme? adminTheme) {
    // Calculate real trends based on current vs previous periods
    final todayCount = stats['today'] ?? 0;
    final completedCount = stats['completed'] ?? 0;
    final lateCount = stats['late'] ?? 0;
    final completionRate = stats['completion_rate'] ?? 0;
    
    // For demonstration, we'll calculate simple trends
    // In a real app, you'd compare with historical data from the repository
    final todayTrend = _calculateTrend(todayCount, stats['yesterday'] ?? 0);
    final completedTrend = _calculateTrend(completedCount, stats['last_week_completed'] ?? 0);
    final lateTrend = _calculateTrend(lateCount, stats['last_month_late'] ?? 0);
    final completionTrend = _calculateTrend(completionRate, stats['last_month_completion_rate'] ?? 0);

    final statCards = [
      _StatCardData(
        title: 'بلاغات اليوم',
        value: todayCount,
        icon: Icons.today_rounded,
        color: AppColors.warning,
        trend: todayTrend,
        subtitle: 'من الأمس',
        route: 'reports_today',
      ),
      _StatCardData(
        title: 'المنجزة',
        value: completedCount,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        trend: completedTrend,
        subtitle: 'هذا الأسبوع',
        route: 'reports_completed',
      ),
      _StatCardData(
        title: 'المتأخرة',
        value: lateCount,
        icon: Icons.warning_rounded,
        color: AppColors.error,
        trend: lateTrend,
        subtitle: 'عن الشهر الماضي',
        route: 'reports_late',
      ),
      _StatCardData(
        title: 'معدل الإنجاز',
        value: completionRate,
        icon: Icons.trending_up_rounded,
        color: AppColors.secondary,
        trend: completionTrend,
        subtitle: 'تحسن مستمر',
        isPercentage: true,
        route: 'completion_rate',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppPadding.medium,
        mainAxisSpacing: AppPadding.medium,
        childAspectRatio: 1.1,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) {
        final card = statCards[index];
        return _buildModernStatCard(theme, adminTheme, card, context);
      },
    );
  }

  /// Calculate percentage trend between current and previous values
  String _calculateTrend(int current, int previous) {
    if (previous == 0) {
      return current > 0 ? '+100%' : '0%';
    }
    
    final difference = current - previous;
    final percentage = ((difference / previous) * 100).round();
    
    if (percentage > 0) {
      return '+$percentage%';
    } else if (percentage < 0) {
      return '$percentage%';
    } else {
      return '0%';
    }
  }

  Widget _buildModernStatCard(
    ThemeData theme,
    AdminPanelTheme? adminTheme,
    _StatCardData cardData,
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(cardData.route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            cardData.color.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cardData.color.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: cardData.color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppPadding.small),
                      decoration: BoxDecoration(
                        color: cardData.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        cardData.icon,
                        color: cardData.color,
                        size: AppSizes.blockWidth * 6,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.small * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: cardData.trend.startsWith('+')
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cardData.trend,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cardData.trend.startsWith('+')
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  '${cardData.value}${cardData.isPercentage ? '%' : ''}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: cardData.color,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.blockHeight * 2.8,
                  ),
                ),
                SizedBox(height: AppSizes.blockHeight * 0.5),
                Text(
                  cardData.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  cardData.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }


}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String trend;
  final String subtitle;
  final bool isPercentage;
  final String route;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.subtitle,
    required this.route,
    this.isPercentage = false,
  });
}
