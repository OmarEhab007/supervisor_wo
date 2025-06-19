import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/auth/auth.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

/// Splash screen shown during app initialization and auth check
class SplashScreen extends StatelessWidget {
  /// Creates a new [SplashScreen] instance
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/');
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
        // Stay on splash screen while status is initial or loading
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F59),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تطبيق المشرف',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Color(0xFF1A2F59),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
