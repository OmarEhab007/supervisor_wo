import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_sizes.dart';

class ReportsRefreshButton<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  final bool Function(S state) isLoading;
  final void Function(BuildContext context) onRefresh;

  const ReportsRefreshButton({
    super.key,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    final theme = Theme.of(context);

    return BlocBuilder<B, S>(
      buildWhen: (previous, current) =>
          isLoading(previous) != isLoading(current),
      builder: (context, state) {
        final loading = isLoading(state);

        return Container(
          padding: const EdgeInsets.all(8),
          width: AppSizes.blockWidth * 12,
          height: AppSizes.blockWidth * 12,
          decoration: BoxDecoration(
            color: theme.canvasColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.canvasColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: loading ? null : () => onRefresh(context),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ImageIcon(
                    const AssetImage('assets/icon/refresh.png'),
                    color: theme.canvasColor,
                  ),
          ),
        );
      },
    );
  }
}
