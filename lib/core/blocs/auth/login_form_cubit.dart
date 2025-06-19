import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/// State for the login form
class LoginFormState extends Equatable {
  /// Creates a new [LoginFormState]
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.rememberMe = false,
    this.isValid = false,
  });

  /// Email entered by the user
  final String email;

  /// Password entered by the user
  final String password;

  /// Whether the password is visible
  final bool isPasswordVisible;

  /// Whether to remember the user
  final bool rememberMe;

  /// Whether the form is valid
  final bool isValid;

  /// Creates a copy of this state with the given fields replaced
  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    bool? rememberMe,
    bool? isValid,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object> get props => [email, password, isPasswordVisible, rememberMe, isValid];
}

/// Cubit for managing login form state
class LoginFormCubit extends Cubit<LoginFormState> {
  /// Creates a new [LoginFormCubit]
  LoginFormCubit() : super(const LoginFormState());

  /// Updates the email
  void emailChanged(String value) {
    final newState = state.copyWith(
      email: value,
      isValid: _validateForm(email: value, password: state.password),
    );
    emit(newState);
  }

  /// Updates the password
  void passwordChanged(String value) {
    final newState = state.copyWith(
      password: value,
      isValid: _validateForm(email: state.email, password: value),
    );
    emit(newState);
  }

  /// Toggles password visibility
  void togglePasswordVisibility() {
    final newState = state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    );
    emit(newState);
  }

  /// Toggles remember me
  void toggleRememberMe() {
    final newState = state.copyWith(
      rememberMe: !state.rememberMe,
    );
    emit(newState);
  }

  /// Validates the form
  bool _validateForm({required String email, required String password}) {
    return email.isNotEmpty && 
           email.contains('@') && 
           password.isNotEmpty && 
           password.length >= 6;
  }
}
