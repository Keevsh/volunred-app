import '../usuario.dart';

class AuthResponse {
  final String message;
  final Usuario usuario;
  final String accessToken;

  AuthResponse({
    required this.message,
    required this.usuario,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
    );
  }
}
