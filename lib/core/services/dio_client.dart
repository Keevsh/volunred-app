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
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Agregar interceptor para JWT
    _dio.interceptors.add(AuthInterceptor());

    // Agregar interceptor personalizado para logging optimizado
    _dio.interceptors.add(SmartLogInterceptor());
  }

  Dio get dio => _dio;
}

/// Interceptor de logging inteligente que no imprime respuestas grandes
class SmartLogInterceptor extends Interceptor {
  static const int maxBodyLength = 1000; // Máximo de caracteres a imprimir

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('\n');
    print('┌─────────────────────────────────────────────────────────────');
    print('│ 🚀 REQUEST');
    print('├─────────────────────────────────────────────────────────────');
    print('│ ${options.method} ${options.uri}');

    if (options.data != null) {
      final dataStr = options.data.toString();
      if (dataStr.length > maxBodyLength) {
        print('│ Body: ${dataStr.substring(0, maxBodyLength)}... [TRUNCATED]');
      } else {
        print('│ Body: $dataStr');
      }
    }
    print('└─────────────────────────────────────────────────────────────\n');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('\n');
    print('┌─────────────────────────────────────────────────────────────');
    print('│ ✅ RESPONSE');
    print('├─────────────────────────────────────────────────────────────');
    print('│ ${response.statusCode} ${response.requestOptions.uri}');

    if (response.data != null) {
      final dataStr = response.data.toString();
      if (dataStr.length > maxBodyLength) {
        // Verificar si contiene base64 (imágenes grandes)
        if (dataStr.contains('base64,') || dataStr.contains('base64')) {
          print(
            '│ Body: [RESPONSE WITH BASE64 - ${dataStr.length} chars total]',
          );
          
          // Intentar mostrar estructura sin base64
          if (response.data is List) {
            print('│ Response Type: List with ${(response.data as List).length} items');
            final firstItem = (response.data as List).isNotEmpty ? (response.data as List)[0] : null;
            if (firstItem is Map) {
              final keys = firstItem.keys.toList();
              print('│ Keys in items: $keys');
              
              // Mostrar un item de ejemplo sin base64
              final cleanItem = Map<String, dynamic>.from(firstItem as Map<String, dynamic>);
              cleanItem.forEach((key, value) {
                if (value is String && value.contains('base64')) {
                  cleanItem[key] = '[BASE64 - ${value.length} chars]';
                } else if (value is String && value.length > 100) {
                  cleanItem[key] = '${value.substring(0, 97)}...';
                }
              });
              print('│ First item (sample): $cleanItem');
            }
          } else if (response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map<String, dynamic>);
            data.forEach((key, value) {
              if (value is String && value.contains('base64')) {
                data[key] = '[BASE64 - ${value.length} chars]';
              }
            });
            print('│ Data (without base64): $data');
          }
        } else {
          print(
            '│ Body: ${dataStr.substring(0, maxBodyLength)}... [TRUNCATED - ${dataStr.length} chars total]',
          );
        }
      } else {
        print('│ Body: $dataStr');
      }
    }
    print('└─────────────────────────────────────────────────────────────\n');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('\n');
    print('┌─────────────────────────────────────────────────────────────');
    print('│ ❌ ERROR');
    print('├─────────────────────────────────────────────────────────────');
    print('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
    print('│ ${err.type}: ${err.message}');
    if (err.response != null) {
      print('│ Status: ${err.response?.statusCode}');
      print('│ Response: ${err.response?.data}');
    }
    print('└─────────────────────────────────────────────────────────────\n');

    handler.next(err);
  }
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Obtener token del storage
    final token = await StorageService.getString(ApiConfig.accessTokenKey);

    print(
      '🔐 [AUTH INTERCEPTOR] Verificando token para ${options.method} ${options.path}',
    );
    print('🔐 [AUTH INTERCEPTOR] Token existe: ${token != null}');
    if (token != null) {
      print('🔐 [AUTH INTERCEPTOR] Token length: ${token.length}');
      print(
        '🔐 [AUTH INTERCEPTOR] Token starts with: ${token.substring(0, min(20, token.length))}...',
      );
      options.headers['Authorization'] = 'Bearer $token';
      print('🔐 [AUTH INTERCEPTOR] Header Authorization agregado');
    } else {
      print(
        '⚠️ [AUTH INTERCEPTOR] No hay token disponible - usuario no autenticado',
      );
    }

    // Safety: Remove id_categoria_organizacion from organization creation requests
    // The API doesn't accept this field during creation
    if (options.method == 'POST' &&
        options.path.contains('/organizaciones') &&
        options.data is Map) {
      final data = options.data as Map<String, dynamic>;
      if (data.containsKey('id_categoria_organizacion')) {
        print(
          '⚠️ INTERCEPTOR: Removiendo id_categoria_organizacion del request',
        );
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
