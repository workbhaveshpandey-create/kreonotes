import 'package:equatable/equatable.dart';

/// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User requested Google sign-in
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested();
}

/// User requested sign-out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User requested account deletion
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
