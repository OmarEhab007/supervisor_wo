import 'package:equatable/equatable.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when checking the current authentication status
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Event triggered when a user signs in with email and password
class AuthSignedInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthSignedInWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event triggered when a user signs up with email and password
class AuthSignedUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String phone;
  final String? plateNumbers;
  final String? plateLetters;
  final String? plateArabicLetters;
  final String? iqamaId;
  final String? workId;

  const AuthSignedUpWithEmail({
    required this.email,
    required this.password,
    required this.username,
    required this.phone,
    this.plateNumbers,
    this.plateLetters,
    this.plateArabicLetters,
    this.iqamaId,
    this.workId,
  });

  @override
  List<Object?> get props => [
    email, 
    password, 
    username, 
    phone, 
    plateNumbers, 
    plateLetters, 
    plateArabicLetters,
    iqamaId, 
    workId
  ];
}

/// Event triggered when a user signs out
class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}

/// Event triggered when an error occurs and needs to be cleared
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
