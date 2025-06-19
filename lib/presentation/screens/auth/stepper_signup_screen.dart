import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/auth/auth.dart';
import 'package:supervisor_wo/core/blocs/auth/signup_form_cubit.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/presentation/widgets/saudi_plate.dart';

/// A stepper-based signup screen with multiple steps
class StepperSignupScreen extends StatelessWidget {
  /// Creates a new [StepperSignupScreen]
  const StepperSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupFormCubit(),
      child: const _StepperSignupScreenView(),
    );
  }
}

class _StepperSignupScreenView extends StatefulWidget {
  const _StepperSignupScreenView();

  @override
  State<_StepperSignupScreenView> createState() =>
      _StepperSignupScreenViewState();
}

class _StepperSignupScreenViewState extends State<_StepperSignupScreenView>
    with TickerProviderStateMixin {
  // Modern design colors with gradients and glass effects
  // ZEFAR KOM color palette
  static const Color _primaryColor = Color(0xFF0B2540);
  static const Color _accentColor = Color(0xFF1F4264);
  static const Color _secondaryAccent = Color(0xFF30587B);
  static const Color _backgroundColor = Color(0xFFF3F5F7);
  static const Color _highlightColor = Color(0xFFC8922A);

  int _currentStep = 0;
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                        padding: EdgeInsets.all(AppSizes.blockWidth * 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.error_outline,
                            color: Colors.white, size: AppSizes.blockWidth * 2),
                      ),
                      SizedBox(width: AppSizes.blockWidth * 2),
                      Expanded(
                          child: Text(state.errorMessage ?? 'فشل في التسجيل')),
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
                              _buildProgressIndicator(),
                              SizedBox(height: AppSizes.blockHeight * 3),
                              Expanded(
                                child: _buildGlassContainer(
                                  child: _buildStepContent(context, authState),
                                ),
                              ),
                              SizedBox(height: AppSizes.blockHeight * 2),
                              _buildNavigationButtons(context, authState),
                              SizedBox(height: AppSizes.blockHeight * 2),
                              _buildLoginLink(context),
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

  /// Builds a modern progress indicator
  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(AppSizes.blockWidth * 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive ? _accentColor : Colors.grey[300],
                        ),
                      ),
                    ),
                    if (index < 2) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: AppSizes.blockHeight * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(
                  0, 'المعلومات الأساسية', Icons.person_rounded),
              _buildStepIndicator(1, 'معلومات الهوية', Icons.badge_rounded),
              _buildStepIndicator(
                  2, 'معلومات المركبة', Icons.directions_car_rounded),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds individual step indicator
  Widget _buildStepIndicator(int step, String title, IconData icon) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: AppSizes.blockWidth * 14,
            height: AppSizes.blockHeight * 6,
            decoration: BoxDecoration(
              color: isActive ? _accentColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _accentColor,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: AppSizes.blockWidth * 6,
            ),
          ),
          SizedBox(height: AppSizes.blockHeight),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: isActive ? _primaryColor : Colors.grey[600],
              fontSize: AppSizes.blockWidth * 3.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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

  /// Builds step content based on current step
  Widget _buildStepContent(BuildContext context, AuthState authState) {
    return BlocBuilder<SignupFormCubit, SignupFormState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _getCurrentStepWidget(context, state),
        );
      },
    );
  }

  /// Gets the current step widget
  Widget _getCurrentStepWidget(BuildContext context, SignupFormState state) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(context, state);
      case 1:
        return _buildIdentityInfoStep(context, state);
      case 2:
        return _buildVehicleInfoStep(context, state);
      default:
        return _buildBasicInfoStep(context, state);
    }
  }

  /// Builds the first step with basic information fields
  Widget _buildBasicInfoStep(BuildContext context, SignupFormState state) {
    return SingleChildScrollView(
      key: const ValueKey('basic_info'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernTextField(
            label: 'اسم المستخدم',
            icon: Icons.person_outline_rounded,
            initialValue: state.username,
            onChanged: (value) =>
                context.read<SignupFormCubit>().usernameChanged(value),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            initialValue: state.email,
            onChanged: (value) =>
                context.read<SignupFormCubit>().emailChanged(value),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            label: 'رقم الجوال',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            initialValue: state.phone,
            onChanged: (value) =>
                context.read<SignupFormCubit>().phoneChanged(value),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            label: 'كلمة المرور',
            icon: Icons.lock_outline_rounded,
            obscureText: !state.isPasswordVisible,
            initialValue: state.password,
            onChanged: (value) =>
                context.read<SignupFormCubit>().passwordChanged(value),
            suffixIcon: IconButton(
              icon: Icon(
                state.isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _accentColor,
              ),
              onPressed: () =>
                  context.read<SignupFormCubit>().togglePasswordVisibility(),
            ),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            label: 'تأكيد كلمة المرور',
            icon: Icons.lock_outline_rounded,
            obscureText: !state.isConfirmPasswordVisible,
            initialValue: state.confirmPassword,
            onChanged: (value) =>
                context.read<SignupFormCubit>().confirmPasswordChanged(value),
            suffixIcon: IconButton(
              icon: Icon(
                state.isConfirmPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _accentColor,
              ),
              onPressed: () => context
                  .read<SignupFormCubit>()
                  .toggleConfirmPasswordVisibility(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the second step with identity information fields
  Widget _buildIdentityInfoStep(BuildContext context, SignupFormState state) {
    return SingleChildScrollView(
      key: const ValueKey('identity_info'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernTextField(
            label: 'رقم الإقامة / الهوية',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            initialValue: state.iqamaId,
            onChanged: (value) =>
                context.read<SignupFormCubit>().iqamaIdChanged(value),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            label: 'رقم بطاقة العمل',
            icon: Icons.work_outline_rounded,
            keyboardType: TextInputType.number,
            initialValue: state.workId,
            onChanged: (value) =>
                context.read<SignupFormCubit>().workIdChanged(value),
          ),
          SizedBox(height: AppSizes.blockHeight * 6),
          // Terms and conditions with modern design
          GestureDetector(
            onTap: () => context.read<SignupFormCubit>().toggleAcceptedTerms(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.acceptedTerms
                    ? _accentColor.withValues(alpha: 0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.acceptedTerms ? _accentColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: state.acceptedTerms
                          ? const LinearGradient(
                              colors: [_accentColor, _primaryColor],
                            )
                          : null,
                      color: state.acceptedTerms ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: state.acceptedTerms
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أوافق على الشروط والأحكام وسياسة الخصوصية',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the third step with vehicle plate information fields
  Widget _buildVehicleInfoStep(BuildContext context, SignupFormState state) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('vehicle_info'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudi plate preview with modern container
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: SaudiLicensePlate(
                englishNumbers:
                    state.plateNumbers.isEmpty ? '0000' : state.plateNumbers,
                arabicLetters: state.plateArabicLetters.isEmpty
                    ? 'أ ب ج'
                    : state.plateArabicLetters,
                englishLetters: state.plateEnglishLetters.isEmpty
                    ? 'A B C'
                    : state.plateEnglishLetters,
              ),
            ),
          ),
          SizedBox(height: AppSizes.blockHeight * 2),

          // Plate information fields
          _buildModernTextField(
            label: 'أرقام اللوحة',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            initialValue: state.plateNumbers,
            onChanged: (value) =>
                context.read<SignupFormCubit>().plateNumbersChanged(value),
          ),
          SizedBox(height: AppSizes.blockHeight * 2),
          _buildModernTextField(
            label: 'الحروف العربية',
            icon: Icons.text_fields_rounded,
            initialValue: state.plateArabicLetters,
            onChanged: (value) => context
                .read<SignupFormCubit>()
                .plateArabicLettersChanged(value),
          ),
          SizedBox(height: AppSizes.blockHeight * 2),
          _buildModernTextField(
            label: 'الحروف الإنجليزية',
            icon: Icons.text_fields_rounded,
            initialValue: state.plateEnglishLetters,
            onChanged: (value) => context
                .read<SignupFormCubit>()
                .plateEnglishLettersChanged(value),
          ),

          // Helper text with modern design
        ],
      ),
    );
  }

  /// Builds step header with modern design
  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppSizes.blockWidth * 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentColor, _primaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSizes.blockWidth * 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(icon, size: AppSizes.blockWidth * 6, color: Colors.white),
          ),
          SizedBox(width: AppSizes.blockWidth * 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build modern text fields
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
              margin: EdgeInsets.all(AppSizes.blockWidth * 2),
              padding: EdgeInsets.all(AppSizes.blockWidth * 2),
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
              borderSide: const BorderSide(color: _accentColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.blockWidth * 2,
                vertical: AppSizes.blockHeight * 2.5),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          initialValue: initialValue,
          onChanged: onChanged,
          style: theme.textTheme.displayMedium?.copyWith(
            color: _primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Builds modern navigation buttons
  Widget _buildNavigationButtons(BuildContext context, AuthState authState) {
    final theme = Theme.of(context);
    return BlocBuilder<SignupFormCubit, SignupFormState>(
      builder: (context, state) {
        return Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accentColor,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          if (_currentStep > 0) {
                            _currentStep--;
                          }
                        });
                      },
                      child: Center(
                        child: Text(
                          'السابق',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.blockWidth * 6),
            ],
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: Container(
                height: AppSizes.blockHeight * 7,
                decoration: BoxDecoration(
                  color: _isCurrentStepValid(state) ||
                          (_currentStep == 2 && _isLastStepValid(state))
                      ? _accentColor
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(16),
                  //
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isCurrentStepValid(state) ||
                            (_currentStep == 2 && _isLastStepValid(state))
                        ? () {
                            if (_currentStep < 2) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              _handleSignup(context, state);
                            }
                          }
                        : () => _showValidationError(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authState.status == AuthStatus.loading) ...[
                              SizedBox(
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
                              _currentStep < 2 ? 'التالي' : 'تسجيل',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentStep < 2) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: AppSizes.blockWidth * 4,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the login link section with modern design
  Widget _buildLoginLink(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.goNamed('login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'تسجيل الدخول',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'لديك حساب بالفعل؟',
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: AppSizes.blockWidth * 4.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Validates the current step
  bool _isCurrentStepValid(SignupFormState state) {
    switch (_currentStep) {
      case 0:
        return state.username.isNotEmpty &&
            state.email.isNotEmpty &&
            state.email.contains('@') &&
            state.phone.isNotEmpty &&
            state.password.isNotEmpty &&
            state.password.length >= 6 &&
            state.confirmPassword == state.password;
      case 1:
        return state.iqamaId.isNotEmpty &&
            state.workId.isNotEmpty &&
            state.acceptedTerms;
      case 2:
        return state.plateNumbers.isNotEmpty &&
            state.plateArabicLetters.isNotEmpty &&
            state.plateEnglishLetters.isNotEmpty;
      default:
        return false;
    }
  }

  /// Validates the last step
  bool _isLastStepValid(SignupFormState state) {
    return _isCurrentStepValid(state);
  }

  /// Shows a modern validation error message
  void _showValidationError() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_rounded,
                    color: Colors.white, size: AppSizes.blockWidth * 4),
              ),
              SizedBox(width: AppSizes.blockWidth * 4),
              Expanded(
                child: Text(
                  'يرجى إكمال جميع الحقول المطلوبة',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: AppSizes.blockWidth * 4.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    // Add a subtle shake animation to draw attention
    _slideController.reset();
    _slideController.forward();
  }

  /// Handles the signup button press
  void _handleSignup(BuildContext context, SignupFormState state) {
    context.read<AuthBloc>().add(
          AuthSignedUpWithEmail(
            email: state.email,
            password: state.password,
            username: state.username,
            phone: state.phone,
            iqamaId: state.iqamaId,
            workId: state.workId,
            plateNumbers: state.plateNumbers,
            plateLetters: state.plateEnglishLetters,
            plateArabicLetters: state.plateArabicLetters,
          ),
        );
  }
}
