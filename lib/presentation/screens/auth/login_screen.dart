import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/auth/auth.dart';
import 'package:supervisor_wo/core/blocs/auth/login_form_cubit.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

/// Login screen for the application
class LoginScreen extends StatelessWidget {
  /// Creates a new [LoginScreen]
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginFormCubit(),
      child: const _LoginScreenView(),
    );
  }
}

class _LoginScreenView extends StatefulWidget {
  const _LoginScreenView();

  @override
  State<_LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<_LoginScreenView>
    with TickerProviderStateMixin {
  // ZEFAR KOM color palette
  static const Color _primaryColor = Color(0xFF0B2540);
  static const Color _accentColor = Color(0xFF1F4264);
  static const Color _secondaryAccent = Color(0xFF30587B);
  static const Color _backgroundColor = Color(0xFFF3F5F7);
  static const Color _highlightColor = Color(0xFFC8922A);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _backgroundColor,
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              context.go('/');
            } else if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.error_outline,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              state.errorMessage ?? 'فشل في تسجيل الدخول')),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(16),
                ),
              );
              context.read<AuthBloc>().add(const AuthErrorCleared());
            }
          },
          builder: (context, authState) {
            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.blockWidth * 4),
                          child: Column(
                            children: [
                              SizedBox(height: AppSizes.blockHeight * 3),
                              _buildHeader(),
                              SizedBox(height: AppSizes.blockHeight * 4),
                              Expanded(
                                child: _buildGlassContainer(
                                  child: _buildLoginForm(context, authState),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// باقي الكود لا يتغير إلا باستخدام الألوان الجديدة أعلاه حيث يلزم

  /// Builds the modern header section
  Widget _buildHeader() {
    AppSizes.init(context);
    return Image.asset('assets/images/logo.png',
        width: AppSizes.blockHeight * 15,
        height: AppSizes.blockHeight * 15,
        fit: BoxFit.contain);
  }

  /// Builds glass morphism container
  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  /// Builds the login form with modern design
  Widget _buildLoginForm(BuildContext context, AuthState authState) {
    AppSizes.init(context);
    final theme = Theme.of(context);
    return BlocBuilder<LoginFormCubit, LoginFormState>(
      builder: (context, state) {
        final loginCubit = context.read<LoginFormCubit>();

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email Field
                _buildModernTextField(
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  initialValue: state.email,
                  onChanged: loginCubit.emailChanged,
                ),
                SizedBox(height: AppSizes.blockHeight * 2),

                // Password Field
                _buildModernTextField(
                  label: 'كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !state.isPasswordVisible,
                  initialValue: state.password,
                  onChanged: loginCubit.passwordChanged,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _accentColor,
                    ),
                    onPressed: loginCubit.togglePasswordVisibility,
                  ),
                ),
                SizedBox(height: AppSizes.blockHeight * 2),

                // Remember Me and Forgot Password
                Row(
                  children: [
                    GestureDetector(
                      onTap: loginCubit.toggleRememberMe,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              state.rememberMe ? Colors.white : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: state.rememberMe
                                ? _accentColor
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: state.rememberMe
                                    ? _accentColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: state.rememberMe
                                  ? Icon(Icons.check_rounded,
                                      color: Colors.white,
                                      size: AppSizes.blockHeight * 1.5)
                                  : null,
                            ),
                            SizedBox(width: AppSizes.blockWidth * 2),
                            Text(
                              'تذكرني',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: _accentColor,
                                fontSize: AppSizes.blockHeight * 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: AppSizes.blockHeight * 4),

                // Login Button
                Container(
                  height: AppSizes.blockHeight * 7,
                  decoration: BoxDecoration(
                    color: state.isValid ? _primaryColor : Colors.grey[400],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: state.isValid
                        ? [
                            BoxShadow(
                              color: state.isValid
                                  ? _accentColor.withValues(alpha: 0.4)
                                  : Colors.grey[400]!,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: state.isValid
                          ? () => _handleLogin(context, state)
                          : null,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authState.status == AuthStatus.loading) ...[
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              'تسجيل الدخول',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: AppSizes.blockHeight * 2,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                //SizedBox(height: AppSizes.blockHeight * 2),
              ],
            ),
            _buildSignUpLink(context),
          ],
        );
      },
    );
  }

  /// Helper method to build modern text fields matching the stepper design
  Widget _buildModernTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required String initialValue,
    required Function(String) onChanged,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: theme.textTheme.displayMedium,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _highlightColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.blockWidth * 2,
                vertical: AppSizes.blockHeight * 2),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          initialValue: initialValue,
          onChanged: onChanged,
          style: theme.textTheme.displayMedium,
        ),
      ),
    );
  }

  /// Builds the sign up link section with modern design
  Widget _buildSignUpLink(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ليس لديك حساب؟',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF00224D),
                    // gradient: const LinearGradient(
                    //   colors: [
                    //     Color(0xFF3B82F6),
                    //     Color.fromARGB(255, 92, 107, 246)
                    //   ],
                    // ),
                    borderRadius: BorderRadius.circular(12),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: const Color(0xFF3B82F6).withOpacity(0.3),
                    //     blurRadius: 8,
                    //     offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.pushNamed('stepper_signup'),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.view_timeline_outlined,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handles the login button press
  void _handleLogin(BuildContext context, LoginFormState state) {
    if (state.isValid) {
      context.read<AuthBloc>().add(
            AuthSignedInWithEmail(
              email: state.email,
              password: state.password,
            ),
          );
    }
  }
}
