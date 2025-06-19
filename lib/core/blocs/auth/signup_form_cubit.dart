import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// State for the signup form
class SignupFormState extends Equatable {
  /// Creates a new [SignupFormState]
  const SignupFormState({
    this.username = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.iqamaId = '',
    this.workId = '',
    this.plateNumbers = '',
    this.plateEnglishLetters = '',
    this.plateArabicLetters = '',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.acceptedTerms = false,
    this.isValid = false,
  });

  /// Username entered by the user
  final String username;
  
  /// Email entered by the user
  final String email;
  
  /// Phone number entered by the user
  final String phone;
  
  /// Password entered by the user
  final String password;
  
  /// Confirm password entered by the user
  final String confirmPassword;
  
  /// Iqama ID entered by the user
  final String iqamaId;
  
  /// Work ID entered by the user
  final String workId;
  
  /// Plate numbers entered by the user
  final String plateNumbers;
  
  /// Plate English letters entered by the user
  final String plateEnglishLetters;
  
  /// Plate Arabic letters entered by the user
  final String plateArabicLetters;
  
  /// Whether the password is visible
  final bool isPasswordVisible;
  
  /// Whether the confirm password is visible
  final bool isConfirmPasswordVisible;
  
  /// Whether the user accepted the terms
  final bool acceptedTerms;
  
  /// Whether the form is valid
  final bool isValid;

  /// Creates a copy of this state with the given fields replaced
  SignupFormState copyWith({
    String? username,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    String? iqamaId,
    String? workId,
    String? plateNumbers,
    String? plateEnglishLetters,
    String? plateArabicLetters,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? acceptedTerms,
    bool? isValid,
  }) {
    return SignupFormState(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      iqamaId: iqamaId ?? this.iqamaId,
      workId: workId ?? this.workId,
      plateNumbers: plateNumbers ?? this.plateNumbers,
      plateEnglishLetters: plateEnglishLetters ?? this.plateEnglishLetters,
      plateArabicLetters: plateArabicLetters ?? this.plateArabicLetters,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object> get props => [
    username,
    email,
    phone,
    password,
    confirmPassword,
    iqamaId,
    workId,
    plateNumbers,
    plateEnglishLetters,
    plateArabicLetters,
    isPasswordVisible,
    isConfirmPasswordVisible,
    acceptedTerms,
    isValid,
  ];
}

/// Cubit for managing signup form state
class SignupFormCubit extends Cubit<SignupFormState> {
  /// Creates a new [SignupFormCubit]
  SignupFormCubit() : super(const SignupFormState());

  /// Updates the username
  void usernameChanged(String value) {
    emit(state.copyWith(
      username: value,
      isValid: _validateForm(username: value),
    ));
  }

  /// Updates the email
  void emailChanged(String value) {
    emit(state.copyWith(
      email: value,
      isValid: _validateForm(email: value),
    ));
  }

  /// Updates the phone
  void phoneChanged(String value) {
    emit(state.copyWith(
      phone: value,
      isValid: _validateForm(phone: value),
    ));
  }

  /// Updates the password
  void passwordChanged(String value) {
    emit(state.copyWith(
      password: value,
      isValid: _validateForm(password: value),
    ));
  }

  /// Updates the confirm password
  void confirmPasswordChanged(String value) {
    emit(state.copyWith(
      confirmPassword: value,
      isValid: _validateForm(confirmPassword: value),
    ));
  }

  /// Updates the iqama ID
  void iqamaIdChanged(String value) {
    emit(state.copyWith(
      iqamaId: value,
      isValid: _validateForm(iqamaId: value),
    ));
  }

  /// Updates the work ID
  void workIdChanged(String value) {
    emit(state.copyWith(
      workId: value,
      isValid: _validateForm(workId: value),
    ));
  }

  /// Updates the plate numbers
  void plateNumbersChanged(String value) {
    emit(state.copyWith(
      plateNumbers: value,
      isValid: _validateForm(plateNumbers: value),
    ));
  }

  /// Updates the plate English letters
  void plateEnglishLettersChanged(String value) {
    emit(state.copyWith(
      plateEnglishLetters: value,
      isValid: _validateForm(plateEnglishLetters: value),
    ));
  }

  /// Updates the plate Arabic letters
  void plateArabicLettersChanged(String value) {
    emit(state.copyWith(
      plateArabicLetters: value,
      isValid: _validateForm(plateArabicLetters: value),
    ));
  }

  /// Toggles password visibility
  void togglePasswordVisibility() {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  /// Toggles confirm password visibility
  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    ));
  }

  /// Toggles accepted terms
  void toggleAcceptedTerms() {
    emit(state.copyWith(
      acceptedTerms: !state.acceptedTerms,
      isValid: _validateForm(acceptedTerms: !state.acceptedTerms),
    ));
  }

  /// Validates the form
  bool _validateForm({
    String? username,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    String? iqamaId,
    String? workId,
    String? plateNumbers,
    String? plateEnglishLetters,
    String? plateArabicLetters,
    bool? acceptedTerms,
  }) {
    final currentUsername = username ?? state.username;
    final currentEmail = email ?? state.email;
    final currentPhone = phone ?? state.phone;
    final currentPassword = password ?? state.password;
    final currentConfirmPassword = confirmPassword ?? state.confirmPassword;
    final currentAcceptedTerms = acceptedTerms ?? state.acceptedTerms;

    // Required fields validation
    final requiredFieldsValid = 
        currentUsername.isNotEmpty &&
        currentEmail.isNotEmpty && 
        currentEmail.contains('@') &&
        currentPhone.isNotEmpty &&
        currentPassword.isNotEmpty && 
        currentPassword.length >= 6 &&
        currentConfirmPassword == currentPassword;

    // Terms must be accepted
    return requiredFieldsValid && currentAcceptedTerms;
  }
}
