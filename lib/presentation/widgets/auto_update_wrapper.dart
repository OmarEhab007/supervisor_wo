import 'package:flutter/material.dart';
import 'package:supervisor_wo/core/services/auto_update_service.dart';

/// Invisible wrapper that only initializes auto-update service
/// Does not modify or interfere with child widget functionality
class AutoUpdateWrapper extends StatefulWidget {
  final Widget child;

  const AutoUpdateWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AutoUpdateWrapper> createState() => _AutoUpdateWrapperState();
}

class _AutoUpdateWrapperState extends State<AutoUpdateWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auto-update service (fails silently if there are issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoUpdateService.instance.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Just return the child - no modification to existing functionality
    return widget.child;
  }
}
