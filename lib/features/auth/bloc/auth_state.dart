import 'package:equatable/equatable.dart';
import '../../../core/models/usuario.dart';
import '../../../core/models/dto/response_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Usuario usuario;
  final AuthResponse? authResponse; // Respuesta completa del login (incluye perfiles)

  const AuthAuthenticated(this.usuario, {this.authResponse});

  @override
  List<Object?> get props => [usuario, authResponse];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
