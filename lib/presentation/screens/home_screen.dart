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
                    color: AppColors.primary.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.8),
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
                            color: Colors.black.withOpacity(0.3),
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
                      ) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Icon(
                        Icons.refresh_rounded,
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
                              top: AppPadding.medium
                            ),
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
      padding: EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأقسام الرئيسية',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: AppSizes.blockHeight * 2.2,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.large),
          
          // Dashboard-style navigation grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppPadding.medium,
            mainAxisSpacing: AppPadding.medium,
            childAspectRatio: 1.1,
            children: [
              _buildDashboardStyleCard(
                context,
                title: 'الصيانة الدورية',
                subtitle: 'إدارة تقارير الصيانة',
                icon: Icons.engineering_rounded,
                color: AppColors.secondary,
                onTap: isLoading ? () {} : () => context.pushNamed('maintenance'),
                isLoading: isLoading,
              ),
              _buildDashboardStyleCard(
                context,
                title: 'البلاغات',
                subtitle: 'متابعة وإدارة البلاغات',
                icon: Icons.report_problem_rounded,
                color: AppColors.primary,
                onTap: isLoading ? () {} : () => context.pushNamed('reports'),
                isLoading: isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStyleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.02),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
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
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: AppSizes.blockWidth * 6,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(AppPadding.small * 0.8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: color,
                            size: AppSizes.blockWidth * 3.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: AppSizes.blockHeight * 1.6,
                      ),
                    ),
                    SizedBox(height: AppSizes.blockHeight * 0.3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: AppSizes.blockHeight * 1.2,
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
