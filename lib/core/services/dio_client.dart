import 'package:dio/dio.dart';
import 'dart:math';
import '../config/api_config.dart';
import 'storage_service.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Agregar interceptor para JWT
    _dio.interceptors.add(AuthInterceptor());

    // Agregar interceptor para logging (desarrollo)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Obtener token del storage
    final token = await StorageService.getString(ApiConfig.accessTokenKey);

    print('🔐 [AUTH INTERCEPTOR] Verificando token para ${options.method} ${options.path}');
    print('🔐 [AUTH INTERCEPTOR] Token existe: ${token != null}');
    if (token != null) {
      print('🔐 [AUTH INTERCEPTOR] Token length: ${token.length}');
      print('🔐 [AUTH INTERCEPTOR] Token starts with: ${token.substring(0, min(20, token.length))}...');
      options.headers['Authorization'] = 'Bearer $token';
      print('🔐 [AUTH INTERCEPTOR] Header Authorization agregado');
    } else {
      print('⚠️ [AUTH INTERCEPTOR] No hay token disponible - usuario no autenticado');
    }

    // Safety: Remove id_categoria_organizacion from organization creation requests
    // The API doesn't accept this field during creation
    if (options.method == 'POST' && 
        options.path.contains('/organizaciones') && 
        options.data is Map) {
      final data = options.data as Map<String, dynamic>;
      if (data.containsKey('id_categoria_organizacion')) {
        print('⚠️ INTERCEPTOR: Removiendo id_categoria_organizacion del request');
        data.remove('id_categoria_organizacion');
        options.data = data;
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Manejar error 401 (token expirado o inválido)
    if (err.response?.statusCode == 401) {
      // Limpiar storage y redirigir a login
      StorageService.clear();
      // Aquí podrías emitir un evento o usar un stream para notificar
      // que el usuario debe hacer login de nuevo
    }

    return handler.next(err);
  }
}
