import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_sizes.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed('modern_profile');
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: ImageIcon(
            const AssetImage('assets/icon/profile.png'),
            color: Colors.white,
            size: AppSizes.blockHeight * 3,
          ),
        ),
      ),
    );
  }
}
