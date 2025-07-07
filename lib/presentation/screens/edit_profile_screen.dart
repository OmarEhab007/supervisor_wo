import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_bloc.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_event.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_state.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/user_profile.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

/// Modern edit profile screen with smooth animations and validation
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Form controllers
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _iqamaController;
  late final TextEditingController _workIdController;
  late final TextEditingController _plateNumbersController;
  late final TextEditingController _plateEnglishController;
  late final TextEditingController _plateArabicController;

  // Focus nodes for smooth transitions
  final Map<String, FocusNode> _focusNodes = {};

  // Validation states
  final Map<String, String?> _errors = {};
  bool _hasChanges = false;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _initializeFocusNodes();
    _setupFormValidation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposeControllers();
    _disposeFocusNodes();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController(text: widget.profile.username);
    _emailController = TextEditingController(text: widget.profile.email);

    // Format phone number for editing - remove +966 prefix and show only local number (7 digits)
    String phoneForEditing = widget.profile.phone;
    if (phoneForEditing.startsWith('+966')) {
      phoneForEditing = phoneForEditing.substring(4);
    }
    // Remove leading zero if present
    if (phoneForEditing.startsWith('0')) {
      phoneForEditing = phoneForEditing.substring(1);
    }
    _phoneController = TextEditingController(text: phoneForEditing);

    _iqamaController =
        TextEditingController(text: widget.profile.iqamaId ?? '');
    _workIdController =
        TextEditingController(text: widget.profile.workId ?? '');
    _plateNumbersController =
        TextEditingController(text: widget.profile.plateNumbers ?? '');
    _plateEnglishController =
        TextEditingController(text: widget.profile.plateEnglishLetters ?? '');
    _plateArabicController =
        TextEditingController(text: widget.profile.plateArabicLetters ?? '');
  }

  void _initializeFocusNodes() {
    _focusNodes['username'] = FocusNode();
    _focusNodes['email'] = FocusNode();
    _focusNodes['phone'] = FocusNode();
    _focusNodes['iqama'] = FocusNode();
    _focusNodes['workId'] = FocusNode();
    _focusNodes['plateNumbers'] = FocusNode();
    _focusNodes['plateEnglish'] = FocusNode();
    _focusNodes['plateArabic'] = FocusNode();
  }

  void _setupFormValidation() {
    // Add listeners to detect changes
    _usernameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _iqamaController.addListener(_onFieldChanged);
    _workIdController.addListener(_onFieldChanged);
    _plateNumbersController.addListener(_onFieldChanged);
    _plateEnglishController.addListener(_onFieldChanged);
    _plateArabicController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // Get the current phone for comparison (remove +966 and leading 0) - should be 7 digits
    String currentPhoneForComparison = widget.profile.phone;
    if (currentPhoneForComparison.startsWith('+966')) {
      currentPhoneForComparison = currentPhoneForComparison.substring(4);
    }
    if (currentPhoneForComparison.startsWith('0')) {
      currentPhoneForComparison = currentPhoneForComparison.substring(1);
    }

    final hasChanges = _usernameController.text != widget.profile.username ||
        _emailController.text != widget.profile.email ||
        _phoneController.text != currentPhoneForComparison ||
        _iqamaController.text != (widget.profile.iqamaId ?? '') ||
        _workIdController.text != (widget.profile.workId ?? '') ||
        _plateNumbersController.text != (widget.profile.plateNumbers ?? '') ||
        _plateEnglishController.text !=
            (widget.profile.plateEnglishLetters ?? '') ||
        _plateArabicController.text !=
            (widget.profile.plateArabicLetters ?? '');

    // Check if form is valid
    final isValid = _validateUsername(_usernameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePhone(_phoneController.text) == null;

    if (hasChanges != _hasChanges || isValid != _isValid) {
      setState(() {
        _hasChanges = hasChanges;
        _isValid = isValid;
      });
    }
  }

  void _disposeControllers() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _iqamaController.dispose();
    _workIdController.dispose();
    _plateNumbersController.dispose();
    _plateEnglishController.dispose();
    _plateArabicController.dispose();
  }

  void _disposeFocusNodes() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupervisorBloc, SupervisorState>(
      listener: (context, state) {
        if (state.status == SupervisorStatus.success) {
          _showSuccessMessage();
          context.pop();
        } else if (state.status == SupervisorStatus.failure) {
          _showErrorMessage(state.errorMessage ?? 'حدث خطأ غير متوقع');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: GradientAppBar(
            title: 'تعديل الملف الشخصي',
            subtitle: 'قم بتحديث معلوماتك',
            automaticallyImplyLeading: true,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBody(),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppPadding.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Section
            _buildSectionCard(
              title: 'المعلومات الشخصية',
              icon: Icons.person_rounded,
              iconColor: AppColors.primary,
              children: [
                _buildTextField(
                  controller: _usernameController,
                  focusNode: _focusNodes['username']!,
                  label: 'اسم المستخدم',
                  icon: Icons.person_rounded,
                  validator: _validateUsername,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppPadding.small),
                _buildTextField(
                  controller: _emailController,
                  focusNode: _focusNodes['email']!,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppPadding.small),
                _buildPhoneTextField(),
                SizedBox(height: AppPadding.small),
                _buildTextField(
                  controller: _iqamaController,
                  focusNode: _focusNodes['iqama']!,
                  label: 'رقم الإقامة (اختياري)',
                  icon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),

            SizedBox(height: AppPadding.medium),

            // Work Information Section
            _buildSectionCard(
              title: 'معلومات العمل',
              icon: Icons.work_rounded,
              iconColor: AppColors.secondary,
              children: [
                _buildTextField(
                  controller: _workIdController,
                  focusNode: _focusNodes['workId']!,
                  label: 'الرقم الوظيفي (اختياري)',
                  icon: Icons.badge_rounded,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),

            SizedBox(height: AppPadding.medium),

            // Vehicle Information Section
            _buildSectionCard(
              title: 'معلومات المركبة',
              icon: Icons.directions_car_rounded,
              iconColor: AppColors.warning,
              children: [
                _buildTextField(
                  controller: _plateNumbersController,
                  focusNode: _focusNodes['plateNumbers']!,
                  label: 'أرقام اللوحة (اختياري)',
                  icon: Icons.pin_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppPadding.small),
                _buildTextField(
                  controller: _plateEnglishController,
                  focusNode: _focusNodes['plateEnglish']!,
                  label: 'الحروف الإنجليزية (اختياري)',
                  icon: Icons.text_fields_rounded,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: AppPadding.small),
                _buildTextField(
                  controller: _plateArabicController,
                  focusNode: _focusNodes['plateArabic']!,
                  label: 'الحروف العربية (اختياري)',
                  icon: Icons.language_rounded,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),

            SizedBox(height: AppPadding.extraLarge * 2), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
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
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
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
                  iconColor.withValues(alpha: 0.04),
                  iconColor.withValues(alpha: 0.02),
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
                      colors: [iconColor, iconColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.25),
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
          Padding(
            padding: EdgeInsets.all(AppPadding.medium),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final hasError = _errors[controller.hashCode.toString()] != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
          width: hasError || focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        validator: validator,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: hasError
                ? AppColors.error
                : focusNode.hasFocus
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.medium,
          ),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: hasError
                ? AppColors.error
                : focusNode.hasFocus
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          errorText: _errors[controller.hashCode.toString()],
          errorStyle: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.error,
          ),
        ),
        onChanged: (value) {
          if (validator != null) {
            final error = validator(value);
            setState(() {
              _errors[controller.hashCode.toString()] = error;
            });
          }
          _onFieldChanged();
        },
        onFieldSubmitted: (value) {
          _moveToNextField();
        },
      ),
    );
  }

  Widget _buildPhoneTextField() {
    final theme = Theme.of(context);
    final hasError = _errors[_phoneController.hashCode.toString()] != null;
    final focusNode = _focusNodes['phone']!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
          width: hasError || focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: _phoneController,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        validator: _validatePhone,
        inputFormatters: [
          // Only allow digits
          FilteringTextInputFormatter.digitsOnly,
          // Limit to 7 digits (we'll accept up to 7, but validate for 7)
          LengthLimitingTextInputFormatter(7),
        ],
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'رقم الهاتف',
          prefixIcon: Icon(
            Icons.phone_rounded,
            color: hasError
                ? AppColors.error
                : focusNode.hasFocus
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          // Add +966 prefix text
          prefixText: '+966 ',
          prefixStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppPadding.medium,
            vertical: AppPadding.medium,
          ),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: hasError
                ? AppColors.error
                : focusNode.hasFocus
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          errorText: _errors[_phoneController.hashCode.toString()],
          errorStyle: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.error,
          ),
          helperText: 'أدخل 7 أرقام (5xxxxxx)',
          helperStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        onChanged: (value) {
          // Remove leading zero if user types it
          if (value.startsWith('0') && value.length > 1) {
            final newValue = value.substring(1);
            _phoneController.value = _phoneController.value.copyWith(
              text: newValue,
              selection: TextSelection.collapsed(offset: newValue.length),
            );
            return;
          }

          if (_validatePhone(value) != null) {
            setState(() {
              _errors[_phoneController.hashCode.toString()] =
                  _validatePhone(value);
            });
          } else {
            setState(() {
              _errors[_phoneController.hashCode.toString()] = null;
            });
          }
          _onFieldChanged();
        },
        onFieldSubmitted: (value) {
          _moveToNextField();
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel Button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: TextButton(
                  onPressed: _handleCancel,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'إلغاء',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ),
            ),

            SizedBox(width: AppPadding.medium),

            // Save Button
            Expanded(
              child: BlocBuilder<SupervisorBloc, SupervisorState>(
                builder: (context, state) {
                  final isLoading = state.status == SupervisorStatus.loading;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _hasChanges && _isValid
                          ? LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight
                              ],
                            )
                          : null,
                      color: !_hasChanges || !_isValid
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _hasChanges && _isValid
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: TextButton(
                      onPressed: _hasChanges && _isValid && !isLoading
                          ? _handleSave
                          : null,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'حفظ التغييرات',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Validation methods
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'اسم المستخدم قصير جداً';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    final phoneNumber = value.trim();

    // Saudi phone numbers should be 9 digits starting with 5
    if (phoneNumber.length != 7) {
      return 'رقم الهاتف يجب أن يكون 7 أرقام';
    }

    if (!phoneNumber.startsWith('5')) {
      return 'رقم الهاتف يجب أن يبدأ بـ 5';
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d{7}$').hasMatch(phoneNumber)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }

    return null;
  }

  // Navigation and form handling
  void _moveToNextField() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.nextFocus();
    }
  }

  void _handleCancel() {
    if (_hasChanges) {
      _showCancelConfirmation();
    } else {
      context.pop();
    }
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // Format phone number: add +966 prefix and remove leading zero if present
      String formattedPhone = _phoneController.text.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      formattedPhone = '+966$formattedPhone';

      final updatedProfile = widget.profile.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: formattedPhone,
        iqamaId: _iqamaController.text.trim().isEmpty
            ? null
            : _iqamaController.text.trim(),
        workId: _workIdController.text.trim().isEmpty
            ? null
            : _workIdController.text.trim(),
        plateNumbers: _plateNumbersController.text.trim().isEmpty
            ? null
            : _plateNumbersController.text.trim(),
        plateEnglishLetters: _plateEnglishController.text.trim().isEmpty
            ? null
            : _plateEnglishController.text.trim(),
        plateArabicLetters: _plateArabicController.text.trim().isEmpty
            ? null
            : _plateArabicController.text.trim(),
        updatedAt: DateTime.now(),
      );

      context
          .read<SupervisorBloc>()
          .add(SupervisorProfileUpdated(updatedProfile));
    }
  }

  // Dialogs and messages
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.warning),
            SizedBox(width: AppPadding.small),
            Text(
              'تجاهل التغييرات؟',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        content: Text(
          'سيتم فقدان جميع التغييرات غير المحفوظة.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'الاستمرار في التعديل',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'تجاهل التغييرات',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppPadding.small),
            Text(
              'تم حفظ التغييرات بنجاح',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Use white for snackbar text
                  ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: AppPadding.small),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // Use white for snackbar text
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
