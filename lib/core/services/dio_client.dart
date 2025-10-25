import 'package:dio/dio.dart';
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

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
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
