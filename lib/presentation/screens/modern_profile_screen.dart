import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:supervisor_wo/core/blocs/auth/auth_event.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_bloc.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_event.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/user_profile.dart';
import 'package:supervisor_wo/presentation/widgets/saudi_plate.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';

/// A modern profile screen that displays user data with web dashboard design
class ModernProfileScreen extends StatelessWidget {
  const ModernProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: const _ModernProfileScreenBody(),
    );
  }
}

class _ModernProfileScreenBody extends StatelessWidget {
  const _ModernProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);

    return BlocListener<SupervisorBloc, SupervisorState>(
      listener: (context, state) {
        if (state.status == SupervisorStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to load profile'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  context
                      .read<SupervisorBloc>()
                      .add(const SupervisorRefreshed());
                },
              ),
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: GradientAppBar(
            title: 'الملف الشخصي',
            subtitle: 'معلوماتك الشخصية',
            automaticallyImplyLeading: false,
            showRefreshButton: false,
            onRefresh: () =>
                context.read<SupervisorBloc>().add(const SupervisorRefreshed()),
            isLoading: context.select<SupervisorBloc, bool>(
              (bloc) => bloc.state.status == SupervisorStatus.loading,
            ),
          ),
          body: BlocBuilder<SupervisorBloc, SupervisorState>(
            builder: (context, state) {
              final isLoading = state.status == SupervisorStatus.initial ||
                  (state.status == SupervisorStatus.loading &&
                      state.profile == null);

              if (state.status == SupervisorStatus.failure &&
                  state.profile == null) {
                return _buildErrorState(
                    context, state.errorMessage ?? 'Failed to load profile');
              }

              final profile = isLoading
                  ? UserProfile(
                      id: 'fake_id',
                      username: 'اسم المستخدم',
                      email: 'email@email.com',
                      phone: '+966500000000',
                      plateNumbers: '1234',
                      plateEnglishLetters: 'ABC',
                      plateArabicLetters: 'أ ب ج',
                      iqamaId: '1234567890',
                      workId: '987654321',
                      techniciansDetailed: [
                        Technician(
                          name: 'أحمد محمد',
                          profession: 'فني كهرباء',
                          workId: '12345',
                          phone: '+966501234567',
                        ),
                        Technician(
                          name: 'سعد العلي',
                          profession: 'فني سباكة',
                          workId: '12346',
                        ),
                      ],
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    )
                  : state.profile;

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<SupervisorBloc>()
                      .add(const SupervisorRefreshed());
                },
                child: Skeletonizer(
                  enabled: isLoading,
                  child: _buildProfileContent(context, profile!, isLoading),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the error state UI
  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: EdgeInsets.all(AppPadding.large),
        padding: EdgeInsets.all(AppPadding.extraLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'خطأ في تحميل البيانات',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.small),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.large),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SupervisorBloc>().add(const SupervisorRefreshed());
              },
              icon: const ImageIcon(AssetImage('assets/icon/refresh.png')),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.large,
                  vertical: AppPadding.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main profile content
  Widget _buildProfileContent(
      BuildContext context, UserProfile profile, bool isLoading) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppPadding.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          _buildModernInfoCard(
            context: context,
            title: 'المعلومات الشخصية',
            icon: Icons.person_rounded,
            iconColor: AppColors.primary,
            children: [
              _buildModernInfoItem(
                context: context,
                icon: Icons.person_rounded,
                title: 'اسم المستخدم',
                value: profile.username,
                iconColor: AppColors.primary,
              ),
              _buildModernInfoItem(
                context: context,
                icon: Icons.email_rounded,
                title: 'البريد الإلكتروني',
                value: profile.email,
                iconColor: AppColors.primary,
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: _buildModernInfoItem(
                  context: context,
                  icon: Icons.phone_rounded,
                  title: 'رقم الهاتف',
                  value: _formatPhoneNumber(profile.phone),
                  iconColor: AppColors.success,
                ),
              ),
              if (profile.iqamaId != null && profile.iqamaId!.isNotEmpty)
                _buildModernInfoItem(
                  context: context,
                  icon: Icons.badge_rounded,
                  title: 'رقم الإقامة',
                  value: profile.iqamaId!,
                  iconColor: AppColors.warning,
                ),
            ],
          ),

          SizedBox(height: AppPadding.medium),

          // Vehicle Information
          if (_hasVehicleInfo(profile)) _buildVehicleCard(context, profile),

          if (_hasVehicleInfo(profile)) SizedBox(height: AppPadding.medium),

          // Work Information
          if (profile.workId != null && profile.workId!.isNotEmpty)
            _buildModernInfoCard(
              context: context,
              title: 'معلومات العمل',
              icon: Icons.work_rounded,
              iconColor: AppColors.secondary,
              children: [
                _buildModernInfoItem(
                  context: context,
                  icon: Icons.badge_rounded,
                  title: 'الرقم الوظيفي',
                  value: profile.workId!,
                  iconColor: AppColors.secondary,
                ),
              ],
            ),

          if (profile.workId != null && profile.workId!.isNotEmpty)
            SizedBox(height: AppPadding.medium),

          // Technicians Information
          if (_hasTechniciansInfo(profile))
            _buildTechniciansCard(context, profile),

          if (_hasTechniciansInfo(profile)) SizedBox(height: AppPadding.medium),

          // Settings and Actions
          _buildModernSettingsCard(context, profile),

          SizedBox(height: AppPadding.large),
        ],
      ),
    );
  }

  /// Builds modern information card
  Widget _buildModernInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(0.04),
                  iconColor.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: AppPadding.small),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),

          // Content
          ...children,
        ],
      ),
    );
  }

  /// Builds modern information item
  Widget _buildModernInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          SizedBox(width: AppPadding.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppPadding.small * 0.5),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds vehicle information card
  Widget _buildVehicleCard(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.04),
                  AppColors.secondary.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: AppPadding.small),
                Text(
                  'معلومات المركبة',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          // Plate section
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.secondary.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة المركبة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppPadding.small),
                Center(
                  child: Transform.scale(
                    scale: 0.9,
                    child: SaudiLicensePlate(
                      englishNumbers: profile.plateNumbers ?? '',
                      englishLetters: profile.plateEnglishLetters ?? '',
                      arabicLetters: profile.plateArabicLetters ??
                          _convertToArabicLetters(
                              profile.plateEnglishLetters ?? ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds modern settings card
  Widget _buildModernSettingsCard(BuildContext context,
      [UserProfile? profile]) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.04),
                  AppColors.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: AppPadding.small),
                Text(
                  'الإعدادات والخيارات',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Settings items
          _buildModernSettingItem(
            context: context,
            icon: Icons.edit_rounded,
            title: 'تعديل الملف الشخصي',
            subtitle: 'قم بتحديث معلوماتك الشخصية',
            iconColor: AppColors.primary,
            onTap: () {
              context.push('/edit-profile', extra: profile);
            },
          ),

          _buildModernSettingItem(
            context: context,
            icon: Icons.help_rounded,
            title: 'المساعدة والدعم',
            subtitle: 'احصل على المساعدة والدعم الفني',
            iconColor: AppColors.success,
            onTap: () {
              _showComingSoonDialog(context, 'المساعدة والدعم');
            },
          ),

          _buildModernSettingItem(
            context: context,
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من حسابك الحالي',
            iconColor: AppColors.error,
            onTap: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// Builds modern setting item
  Widget _buildModernSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              SizedBox(width: AppPadding.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: AppPadding.small * 0.5),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows coming soon dialog
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.construction_rounded, color: AppColors.warning),
            SizedBox(width: AppPadding.small),
            Text('قريباً'),
          ],
        ),
        content: Text('سيتم إضافة ميزة "$feature" في التحديث القادم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// Shows the logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error,
                        AppColors.error.withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: AppPadding.large),

                // Title
                Text(
                  'تسجيل الخروج',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppPadding.medium),

                // Content
                Text(
                  'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppPadding.extraLarge),

                // Actions
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'إلغاء',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: AppPadding.medium),

                    // Logout Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<AuthBloc>().add(AuthSignedOut());
                          },
                          child: Text(
                            'تسجيل الخروج',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds technicians information section with modern cards
  Widget _buildTechniciansCard(BuildContext context, UserProfile profile) {
    return _buildModernInfoCard(
      context: context,
      title: 'الفريق',
      icon: Icons.engineering_rounded,
      iconColor: AppColors.success,
      children: [
        // Technicians Cards Container
        Container(
          padding: EdgeInsets.all(AppPadding.medium),
          child: Column(
            children: [
              // Technicians Cards
              ...profile.techniciansDetailed!.asMap().entries.map((entry) {
                final index = entry.key;
                final technician = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == profile.techniciansDetailed!.length - 1
                        ? 0
                        : AppPadding.medium,
                  ),
                  child: _buildModernTechnicianCard(context, technician),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds modern individual technician card
  Widget _buildModernTechnicianCard(
      BuildContext context, Technician technician) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: AppColors.success.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success.withOpacity(0.05),
                    AppColors.success.withOpacity(0.02),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Modern Avatar
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
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.engineering_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppPadding.medium),

                  // Technician Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          technician.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                            fontSize: AppSizes.blockHeight * 1.8,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: AppPadding.small * 0.5),

                        // Profession with icon
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: AppPadding.small * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              SizedBox(width: AppPadding.small * 0.5),
                              Text(
                                technician.profession,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Phone section (if available)
            if (technician.phone != null && technician.phone!.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _makePhoneCall(context, technician.phone!);
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.success.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Phone icon
                        Container(
                          padding: EdgeInsets.all(AppPadding.small * 0.8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(width: AppPadding.small),

                        // Phone number
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'رقم الهاتف',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: AppPadding.small * 0.3),
                                Text(
                                  _formatPhoneNumber(technician.phone!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Call button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _makePhoneCall(context, technician.phone!);
                          },
                          child: Container(
                            padding: EdgeInsets.all(AppPadding.small * 0.8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withOpacity(0.8)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.call_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Makes a phone call to the given number
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, 'لا يمكن إجراء المكالمة على هذا الجهاز');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'حدث خطأ أثناء محاولة الاتصال');
      }
    }
  }

  /// Shows error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Helper methods
  bool _hasTechniciansInfo(UserProfile profile) {
    return profile.techniciansDetailed != null &&
        profile.techniciansDetailed!.isNotEmpty;
  }

  bool _hasVehicleInfo(UserProfile profile) {
    return (profile.plateNumbers != null && profile.plateNumbers!.isNotEmpty) ||
        (profile.plateEnglishLetters != null &&
            profile.plateEnglishLetters!.isNotEmpty) ||
        (profile.plateArabicLetters != null &&
            profile.plateArabicLetters!.isNotEmpty);
  }

  String _convertToArabicLetters(String englishLetters) {
    // Simple conversion map - extend as needed
    final Map<String, String> letterMap = {
      'A': 'أ',
      'B': 'ب',
      'C': 'ج',
      'D': 'د',
      'E': 'ه',
      'F': 'و',
      'G': 'ز',
      'H': 'ح',
      'I': 'ط',
      'J': 'ي',
      'K': 'ك',
      'L': 'ل',
      'M': 'م',
      'N': 'ن',
      'O': 'س',
      'P': 'ع',
      'Q': 'ف',
      'R': 'ص',
      'S': 'ق',
      'T': 'ر',
      'U': 'ش',
      'V': 'ت',
      'W': 'ث',
      'X': 'خ',
      'Y': 'ذ',
      'Z': 'ض',
    };

    return englishLetters
        .split('')
        .map((char) => letterMap[char.toUpperCase()] ?? char)
        .join(' ');
  }

  /// Formats phone number for display: +966 5x xxx xx
  String _formatPhoneNumber(String phone) {
    // If phone doesn't start with +966, return as is
    if (!phone.startsWith('+966')) {
      return phone;
    }

    // Remove +966 prefix to get local number
    String localNumber = phone.substring(4);

    // Remove leading zero if present
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }

    // Format as +966 5x xxx xx (7 digits)
    if (localNumber.length == 7) {
      return '${localNumber.substring(5)} ${localNumber.substring(2, 5)} ${localNumber.substring(0, 2)} 966+';
    }

    // If not 7 digits, return with prefix only
    return '+966 $localNumber';
  }
}
