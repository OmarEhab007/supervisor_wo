import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/theme.dart';
import '../../core/utils/app_sizes.dart';
import 'profile_avatar.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool showProfileAvatar;
  final bool showRefreshButton;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = false,
    this.showProfileAvatar = false,
    this.showRefreshButton = false,
    this.onRefresh,
    this.isLoading,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AppSizes.init(context);

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: false,
      elevation: elevation,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
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
      ),
      title: _buildTitle(theme),
      actions: _buildActions(context),
      foregroundColor: Colors.white,
      bottom: bottom,
    );
  }

  Widget _buildTitle(ThemeData theme) {
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: AppSizes.blockHeight * 1.4,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: AppSizes.blockHeight * 2.2,
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
      );
    }

    return Text(
      title,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontSize: AppSizes.blockHeight * 2.2,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    if (showRefreshButton && onRefresh != null) {
      actionWidgets.add(
        Container(
          margin: EdgeInsets.only(left: AppPadding.small),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onRefresh!();
            },
            icon: AnimatedRotation(
              turns: (isLoading ?? false) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: AppSizes.blockHeight * 2.4,
              ),
            ),
            splashRadius: 24,
            tooltip: 'تحديث',
          ),
        ),
      );
    }

    if (showProfileAvatar) {
      actionWidgets.add(
        Padding(
          padding: EdgeInsets.only(left: AppPadding.medium),
          child: ProfileAvatar(),
        ),
      );
    }

    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets.isNotEmpty ? actionWidgets : null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

class GradientSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final Widget? flexibleSpace;

  const GradientSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.expandedHeight = 120.0,
    this.floating = true,
    this.pinned = true,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = theme.extension<CustomAppBarTheme>();
    final gradientColors = customTheme?.gradientColors ??
        [
          const Color(0xff00224D),
          const Color(0xff27548A),
        ];

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      backgroundColor: gradientColors.first,
      leading: leading,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: flexibleSpace ??
          FlexibleSpaceBar(
            title: Text(
              title,
              style: theme.appBarTheme.titleTextStyle,
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
            ),
          ),
    );
  }
}
