import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/damage_count/damage_count.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/core/services/cache_service.dart';
import 'package:supervisor_wo/models/school_model.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/presentation/widgets/app_loading_indicator.dart';

/// Screen displaying damage schools with tabs for in-progress and completed counts
class DamageSchoolsScreen extends StatefulWidget {
  const DamageSchoolsScreen({super.key});

  @override
  State<DamageSchoolsScreen> createState() => _DamageSchoolsScreenState();
}

class _DamageSchoolsScreenState extends State<DamageSchoolsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0; // Add refresh key to trigger rebuilds

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

    // Load schools when screen opens
    context.read<DamageCountBloc>().add(const DamageCountSchoolsStarted());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Refresh both tabs data
  Future<void> _refreshData() async {
    context.read<DamageCountBloc>().add(const DamageCountSchoolsRefreshed());

    // Trigger rebuild of in-progress tab by changing refresh key
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: GradientAppBar(
            title: 'حصر التوالف',
            subtitle: 'المدارس المسندة إليك لحصر التوالف',
            showRefreshButton: true,
            onRefresh: _refreshData,
            isLoading: context.select<DamageCountBloc, bool>(
              (bloc) => bloc.state.status == DamageCountStatus.loading,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72.0),
              child: Container(
                margin: EdgeInsets.fromLTRB(
                    AppPadding.large, 0, AppPadding.large, AppPadding.medium),
                child: _buildModernTabSelector(),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SafeArea(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildInProgressTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ),
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _showSelectSchoolDialog(context),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'حصر توالف',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
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
                color: Colors.orange.withOpacity(0.08),
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
                  'قيد التنفيذ',
                  Icons.pending_actions_rounded,
                  Colors.orange,
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
  Widget _buildTabOption(
      int index, String title, IconData icon, Color accentColor) {
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
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
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
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(isSelected ? 6 : 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color:
                      isSelected ? accentColor : Colors.white.withOpacity(0.8),
                  size: isSelected ? 18 : 16,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? accentColor
                        : Colors.white.withOpacity(0.9),
                    fontSize: isSelected ? 14 : 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the in-progress tab content
  Widget _buildInProgressTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_refreshKey), // Use refresh key to trigger rebuilds
      future: DraftCountPersistenceService.getInProgressSchools(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final inProgressSchools = snapshot.data ?? [];
        final damageInProgress = inProgressSchools
            .where((school) => school['type'] == 'damage')
            .toList();

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(context, damageInProgress, false),
              SizedBox(height: AppPadding.large),
              _buildInProgressContainer(context, damageInProgress),
            ],
          ),
        );
      },
    );
  }

  /// Build the completed tab content
  Widget _buildCompletedTab() {
    return BlocBuilder<DamageCountBloc, DamageCountState>(
      builder: (context, state) {
        return FutureBuilder<List<DamageCountModel>>(
          future: context
              .read<DamageCountBloc>()
              .repository
              .getDamageCountsForSupervisor(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final completedCounts = snapshot.data ?? [];
            final completedSchools = completedCounts
                .where((count) => count.status == 'submitted')
                .toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(context, completedSchools, true),
                  SizedBox(height: AppPadding.large),
                  _buildCompletedContainer(context, completedSchools),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build stats section for both tabs
  Widget _buildStatsSection(
      BuildContext context, List<dynamic> items, bool isCompleted) {
    final theme = Theme.of(context);
    final totalItems = items.length;
    final color = isCompleted ? AppColors.success : Colors.orange;
    final title = isCompleted ? 'العدد المكتمل' : 'العدد قيد التنفيذ';
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.medium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppSizes.blockHeight * 3,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.blockHeight * 2.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'إجمالي $totalItems مدرسة',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark.withOpacity(0.7),
                        fontSize: AppSizes.blockHeight * 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.small,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  totalItems.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: AppSizes.blockHeight * 2.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build in-progress schools container
  Widget _buildInProgressContainer(
      BuildContext context, List<Map<String, dynamic>> inProgressSchools) {
    final theme = Theme.of(context);

    if (inProgressSchools.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppPadding.extraLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.08),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.pending_actions_rounded,
                size: AppSizes.blockHeight * 8,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'لا توجد مدارس قيد التنفيذ',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'اضغط على "حصر توالف" لبدء حصر جديد',
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
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
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
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.orange,
                  size: AppSizes.blockHeight * 2.4,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المدارس قيد التنفيذ',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'المدارس التي تم البدء في حصر توالفها',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inProgressSchools.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: AppPadding.medium),
            itemBuilder: (context, index) {
              final schoolData = inProgressSchools[index];
              return _buildInProgressSchoolCard(context, schoolData);
            },
          ),
        ],
      ),
    );
  }

  /// Build completed schools container
  Widget _buildCompletedContainer(
      BuildContext context, List<DamageCountModel> completedCounts) {
    final theme = Theme.of(context);

    if (completedCounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppPadding.extraLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.08),
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
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: AppSizes.blockHeight * 8,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'لا توجد مدارس مكتملة',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.blockHeight * 2.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'لم تكمل أي حصر توالف بعد',
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
            color: AppColors.success.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
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
                      'المدارس المكتملة',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: AppSizes.blockHeight * 2.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'المدارس التي تم الانتهاء من حصر توالفها',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedCounts.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: AppPadding.medium),
            itemBuilder: (context, index) {
              final count = completedCounts[index];
              return _buildCompletedSchoolCard(context, count);
            },
          ),
        ],
      ),
    );
  }

  /// Build in-progress school card
  Widget _buildInProgressSchoolCard(
      BuildContext context, Map<String, dynamic> schoolData) {
    final lastUpdated = DateTime.parse(schoolData['lastUpdated']);
    final timeAgo = _getTimeAgo(lastUpdated);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/damage-count-form/${schoolData['schoolId']}',
            extra: {
              'schoolName': schoolData['schoolName'],
              'schoolId': schoolData['schoolId'],
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.blockWidth * 14,
                height: AppSizes.blockWidth * 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange,
                      Colors.orange.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.blockWidth * 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: AppSizes.blockWidth * 2,
                      offset: Offset(0, AppSizes.blockHeight * 0.5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.white,
                  size: AppSizes.blockWidth * 7,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolData['schoolName'],
                      style: TextStyle(
                        fontSize: AppSizes.blockHeight * 2.2,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1E293B),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSizes.blockHeight * 0.5),
                    Text(
                      'آخر تحديث: $timeAgo',
                      style: TextStyle(
                        fontSize: AppSizes.blockHeight * 1.7,
                        fontWeight: FontWeight.w400,
                        color: Colors.orange,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      context.push(
                        '/damage-count-form/${schoolData['schoolId']}',
                        extra: {
                          'schoolName': schoolData['schoolName'],
                          'schoolId': schoolData['schoolId'],
                        },
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(AppSizes.blockWidth * 2),
                    child: Container(
                      padding: EdgeInsets.all(AppPadding.small),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.orange,
                        size: AppSizes.blockWidth * 4.5,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.blockWidth * 1),
                  InkWell(
                    onTap: () =>
                        _showRemoveInProgressDialog(context, schoolData),
                    borderRadius:
                        BorderRadius.circular(AppSizes.blockWidth * 2),
                    child: Container(
                      padding: EdgeInsets.all(AppPadding.small),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[400],
                        size: AppSizes.blockWidth * 4.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build completed school card
  Widget _buildCompletedSchoolCard(
      BuildContext context, DamageCountModel count) {
    final completedDate = count.updatedAt ?? count.createdAt;
    final timeAgo = _getTimeAgo(completedDate);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: AppColors.success.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(width: AppPadding.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.schoolName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1E293B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تم الإكمال: $timeAgo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.success,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _editCompletedDamageCount(context, count),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: Colors.orange[600],
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'تعديل',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to remove in-progress school
  void _showRemoveInProgressDialog(
      BuildContext context, Map<String, dynamic> schoolData) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 24,
              ),
              SizedBox(width: AppPadding.small),
              Text(
                'حذف المسودة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل تريد حذف المسودة لـ "${schoolData['schoolName']}"؟ سيتم فقدان جميع البيانات المحفوظة.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await DraftCountPersistenceService.removeDraftDamageCount(
                  schoolData['schoolId'],
                );
                Navigator.of(dialogContext).pop();
                setState(() {}); // Refresh the UI
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف المسودة بنجاح'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'حذف',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _showSelectSchoolDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.blockWidth * 5),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: AppSizes.screenWidth * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                Container(
                  padding: EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange, Colors.orange.shade300],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: AppPadding.small),
                      Expanded(
                        child: Text(
                          'اختر مدرسة لحصر التوالف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dialog Content
                Expanded(
                  child: _buildAssignedSchoolsList(context, dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the list of assigned schools for damage count selection
  Widget _buildAssignedSchoolsList(
      BuildContext context, BuildContext dialogContext) {
    return BlocBuilder<DamageCountBloc, DamageCountState>(
      builder: (context, state) {
        if (state.status == DamageCountStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.status == DamageCountStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                SizedBox(height: AppPadding.medium),
                Text(
                  'خطأ في تحميل البيانات',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<School>>(
          future: _getAvailableSchoolsForSelection(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final availableSchools = snapshot.data ?? [];

            if (availableSchools.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppPadding.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: AppPadding.medium),
                      Text(
                        'جميع المدارس تم حصر تواليفها',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppPadding.small),
                      Text(
                        'لا توجد مدارس متاحة لحصر توالف جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(AppPadding.medium),
              itemCount: availableSchools.length,
              itemBuilder: (context, index) {
                final school = availableSchools[index];
                return _buildAssignedSchoolCard(context, dialogContext, school);
              },
            );
          },
        );
      },
    );
  }

  /// Get schools available for selection (excluding those with in-progress or completed counts)
  Future<List<School>> _getAvailableSchoolsForSelection() async {
    try {
      final repository = context.read<DamageCountBloc>().repository;

      // Get all assigned schools
      final allAssignedSchools = await repository.getDamageSchools();

      // Get in-progress schools
      final inProgressSchools =
          await DraftCountPersistenceService.getInProgressSchools();
      final inProgressDamageIds = inProgressSchools
          .where((school) => school['type'] == 'damage')
          .map((school) => school['schoolId'] as String)
          .toSet();

      // Get completed damage counts
      final completedCounts = await repository.getDamageCountsForSupervisor();
      final completedSchoolIds = completedCounts
          .where((count) => count.status == 'submitted')
          .map((count) => count.schoolId)
          .toSet();

      // Filter out schools that are in-progress or completed
      final availableSchools = allAssignedSchools.where((school) {
        return !inProgressDamageIds.contains(school.id) &&
            !completedSchoolIds.contains(school.id);
      }).toList();

      return availableSchools;
    } catch (e) {
      print('Error filtering available damage schools: $e');
      rethrow;
    }
  }

  /// Build card for assigned school selection
  Widget _buildAssignedSchoolCard(
    BuildContext context,
    BuildContext dialogContext,
    School school,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.small),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _selectSchoolForDamageCount(context, dialogContext, school),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // School icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppPadding.medium),
                // School details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (school.address.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          school.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow icon to indicate selection
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.orange,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Select school and navigate to damage count form
  void _selectSchoolForDamageCount(
    BuildContext context,
    BuildContext dialogContext,
    School school,
  ) {
    // Close the dialog
    Navigator.of(dialogContext).pop();

    // Navigate to damage count form
    context.push(
      '/damage-count-form/${school.id}',
      extra: {
        'schoolName': school.name,
        'schoolId': school.id,
      },
    );
  }

  /// Edit completed damage count
  void _editCompletedDamageCount(BuildContext context, DamageCountModel count) {
    context.push(
      '/damage-count-form/${count.schoolId}',
      extra: {
        'schoolName': count.schoolName,
        'schoolId': count.schoolId,
        'isEdit': true,
        'existingCount': count,
      },
    );
  }
}
