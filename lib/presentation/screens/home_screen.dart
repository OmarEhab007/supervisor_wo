import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supervisor_wo/core/blocs/home/home_bloc.dart';
import 'package:supervisor_wo/core/blocs/home/home_event.dart';
import 'package:supervisor_wo/core/blocs/home/home_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/presentation/widgets/profile_avatar.dart';
import 'package:supervisor_wo/presentation/widgets/overview_dashboard.dart';
import 'package:supervisor_wo/presentation/widgets/connectivity_banner.dart';

/// The home screen of the supervisor app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    final theme = Theme.of(context);
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.status == HomeStatus.failure) {
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80.0), // Taller app bar
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: false,
                toolbarHeight: 80.0, // Match the preferred size
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: AppSizes.blockHeight * 1.6, // Bigger subtitle
                      ),
                    ),
                    Text(
                      'نتمنى لك يومًا سعيدًا',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: AppSizes.blockHeight * 2.8, // Bigger title
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Refresh button
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<HomeBloc>().add(const HomeRefreshed());
                    },
                    icon: AnimatedRotation(
                      turns: context.select<HomeBloc, bool>(
                        (bloc) => bloc.state.status == HomeStatus.loading,
                      )
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: ImageIcon(
                        const AssetImage('assets/icon/refresh.png'),
                        color: Colors.white,
                        size: AppSizes.blockHeight * 2.6, // Bigger icon
                      ),
                    ),
                    splashRadius: 28,
                    tooltip: 'تحديث',
                  ),

                  // Profile avatar
                  ProfileAvatar(),

                  //SizedBox(width: AppPadding.medium),
                ],
              ),
            ),
          ),
          backgroundColor: AppColors.surfaceLight,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(const HomeRefreshed());
            },
            child: SafeArea(
              child: BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (previous, current) =>
                    previous.stats != current.stats ||
                    previous.status != current.status,
                builder: (context, state) {
                  final isLoading = state.status == HomeStatus.loading;

                  return Skeletonizer(
                    enabled: isLoading,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Connectivity status banner
                          const ConnectivityBanner(),

                          Padding(
                            padding: EdgeInsets.only(
                                right: AppPadding.medium,
                                top: AppPadding.medium),
                            child: Text(
                              'الإحصائيات العامة',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: AppSizes.blockHeight * 2.2,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),

                          // Enhanced Dashboard Section with loading state
                          OverviewDashboard(
                            stats: state.stats,
                            isLoading: isLoading,
                          ),

                          // Navigation buttons with loading state
                          _buildNavigationButtons(context, isLoading),
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

  Widget _buildNavigationButtons(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأقسام الرئيسية',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: AppSizes.blockHeight * 2.0,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.medium),

          // Modern compact horizontal navigation buttons
          Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactNavButton(
                      context,
                      title: 'الصيانة الدورية',
                      icon: Icons.engineering_rounded,
                      color: AppColors.secondary,
                      onTap: isLoading
                          ? () {}
                          : () => context.pushNamed('maintenance'),
                      isLoading: isLoading,
                    ),
                  ),
                  SizedBox(width: AppPadding.small),
                  Expanded(
                    child: _buildCompactNavButton(
                      context,
                      title: 'البلاغات',
                      icon: Icons.report_problem_rounded,
                      color: AppColors.primary,
                      onTap: isLoading
                          ? () {}
                          : () => context.pushNamed('reports'),
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppPadding.small),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactNavButton(
                      context,
                      title: 'حصورات الأعداد',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.secondaryLight,
                      onTap: isLoading
                          ? () {}
                          : () => context.pushNamed('maintenance_schools'),
                      isLoading: isLoading,
                    ),
                  ),
                  SizedBox(width: AppPadding.small),
                  Expanded(
                    child: _buildCompactNavButton(
                      context,
                      title: 'حصر التوالف',
                      icon: Icons.broken_image_rounded,
                      color: Colors.orange,
                      onTap: isLoading
                          ? () {}
                          : () => context.pushNamed('damage_schools'),
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppPadding.small),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactNavButton(
                      context,
                      title: 'مشاهد وتشيك ليست',
                      icon: Icons.school_rounded,
                      color: Colors.blue,
                      onTap: isLoading
                          ? () {}
                          : () {
                              HapticFeedback.lightImpact();
                              context.pushNamed('schools_list');
                            },
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNavButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: AppSizes.blockHeight * 6.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.small,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppPadding.small * 0.8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: AppSizes.blockWidth * 4.5,
                      ),
                    ),
                    SizedBox(width: AppPadding.small),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          fontSize: AppSizes.blockHeight * 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(AppPadding.small * 0.5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: color.withValues(alpha: 0.8),
                        size: AppSizes.blockWidth * 3,
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
