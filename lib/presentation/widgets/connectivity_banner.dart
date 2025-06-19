import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/connectivity/connectivity.dart';

/// Banner widget that displays connectivity status and provides retry options
class ConnectivityBanner extends StatelessWidget {
  final bool showWhenConnected;
  final EdgeInsets margin;
  final Duration animationDuration;
  
  const ConnectivityBanner({
    super.key,
    this.showWhenConnected = false,
    this.margin = const EdgeInsets.all(8.0),
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        // Don't show banner when connected (unless specifically requested)
        if (state.isConnected && !showWhenConnected) {
          return const SizedBox.shrink();
        }

        // Don't show banner in initial state
        if (state is ConnectivityInitial) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: animationDuration,
          margin: margin,
          child: Material(
            color: _getBackgroundColor(state),
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getIcon(state),
                    color: _getIconColor(state),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTitle(state),
                          style: TextStyle(
                            color: _getTextColor(state),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (_getSubtitle(state).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getSubtitle(state),
                            style: TextStyle(
                              color: _getTextColor(state).withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_shouldShowRetryButton(state)) ...[
                    const SizedBox(width: 8),
                    _buildRetryButton(context, state),
                  ],
                  if (state is ConnectivityChecking) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTextColor(state),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetryButton(BuildContext context, ConnectivityState state) {
    return TextButton(
      onPressed: () {
        context.read<ConnectivityBloc>().add(
          const ConnectivityRetryRequested(),
        );
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(60, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: _getTextColor(state).withOpacity(0.1),
        foregroundColor: _getTextColor(state),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: const Text(
        'Retry',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? Colors.green.shade100
            : Colors.orange.shade100;
      case ConnectivityLimited:
        return Colors.orange.shade100;
      case ConnectivityDisconnected:
        return Colors.red.shade100;
      case ConnectivityChecking:
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getTextColor(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? Colors.green.shade800
            : Colors.orange.shade800;
      case ConnectivityLimited:
        return Colors.orange.shade800;
      case ConnectivityDisconnected:
        return Colors.red.shade800;
      case ConnectivityChecking:
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  Color _getIconColor(ConnectivityState state) => _getTextColor(state);

  IconData _getIcon(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? Icons.cloud_done
            : Icons.cloud_queue;
      case ConnectivityLimited:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case ConnectivityDisconnected:
        return Icons.cloud_off;
      case ConnectivityChecking:
        return Icons.sync;
      default:
        return Icons.help_outline;
    }
  }

  String _getTitle(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? 'Connected'
            : 'Limited Service';
      case ConnectivityLimited:
        return 'No Internet';
      case ConnectivityDisconnected:
        return 'Offline';
      case ConnectivityChecking:
        return 'Checking Connection';
      default:
        return 'Unknown Status';
    }
  }

  String _getSubtitle(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? 'All services available'
            : 'Some services may be unavailable';
      case ConnectivityLimited:
        return 'Connected to network but no internet access';
      case ConnectivityDisconnected:
        return 'Check your network connection';
      case ConnectivityChecking:
        return 'Please wait...';
      default:
        return '';
    }
  }

  bool _shouldShowRetryButton(ConnectivityState state) {
    return state is ConnectivityDisconnected ||
           state is ConnectivityLimited ||
           (state is ConnectivityConnected && !state.isSupabaseReachable);
  }
}

/// Compact version of the connectivity banner for minimal space usage
class CompactConnectivityBanner extends StatelessWidget {
  final bool showWhenConnected;
  
  const CompactConnectivityBanner({
    super.key,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        // Don't show banner when connected (unless specifically requested)
        if (state.isConnected && !showWhenConnected) {
          return const SizedBox.shrink();
        }

        // Don't show banner in initial state
        if (state is ConnectivityInitial) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 4,
          color: _getBackgroundColor(state),
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? Colors.green
            : Colors.orange;
      case ConnectivityLimited:
        return Colors.orange;
      case ConnectivityDisconnected:
        return Colors.red;
      case ConnectivityChecking:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Snackbar-style notification for connectivity changes
class ConnectivitySnackbar {
  static void show(BuildContext context, ConnectivityState state) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    messenger.clearSnackBars();

    // Don't show snackbar for checking state or initial connected state
    if (state is ConnectivityChecking || state is ConnectivityInitial) {
      return;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIcon(state),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMessage(state),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(state),
      duration: _getDuration(state),
      action: _shouldShowRetryAction(state)
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                context.read<ConnectivityBloc>().add(
                  const ConnectivityRetryRequested(),
                );
              },
            )
          : null,
    );

    messenger.showSnackBar(snackBar);
  }

  static IconData _getIcon(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        return Icons.cloud_done;
      case ConnectivityLimited:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case ConnectivityDisconnected:
        return Icons.cloud_off;
      default:
        return Icons.help_outline;
    }
  }

  static String _getMessage(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? 'Connected to all services'
            : 'Connected but some services unavailable';
      case ConnectivityLimited:
        return 'Connected to network but no internet';
      case ConnectivityDisconnected:
        return 'No internet connection';
      default:
        return 'Connection status unknown';
    }
  }

  static Color _getBackgroundColor(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        final connectedState = state as ConnectivityConnected;
        return connectedState.isSupabaseReachable
            ? Colors.green
            : Colors.orange;
      case ConnectivityLimited:
        return Colors.orange;
      case ConnectivityDisconnected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Duration _getDuration(ConnectivityState state) {
    switch (state.runtimeType) {
      case ConnectivityConnected:
        return const Duration(seconds: 2);
      case ConnectivityLimited:
        return const Duration(seconds: 5);
      case ConnectivityDisconnected:
        return const Duration(seconds: 8);
      default:
        return const Duration(seconds: 3);
    }
  }

  static bool _shouldShowRetryAction(ConnectivityState state) {
    return state is ConnectivityDisconnected ||
           state is ConnectivityLimited ||
           (state is ConnectivityConnected && !state.isSupabaseReachable);
  }
} 