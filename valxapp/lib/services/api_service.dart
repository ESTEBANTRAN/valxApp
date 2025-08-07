import 'dart:math';
import 'package:dio/dio.dart';
import '../models/account.dart';
import '../models/checker_config.dart';
import '../utils/constants.dart';

class ApiService {
  late Dio _dio;
  final CheckerConfig config;
  final Map<String, dynamic> _cache = {};
  final Random _random = Random();

  ApiService({required this.config}) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: config.requestTimeout),
        receiveTimeout: Duration(seconds: config.requestTimeout),
        headers: {
          'User-Agent': AppConstants.mobileUserAgent,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Configurar interceptores para rate limiting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar delay aleatorio para evitar detección
          if (config.enableRandomDelays) {
            final delay =
                _random.nextInt(
                  config.maxDelayBetweenRequests -
                      config.minDelayBetweenRequests,
                ) +
                config.minDelayBetweenRequests;
            await Future.delayed(Duration(milliseconds: delay));
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Manejar errores de red
          String errorMessage = 'unknown_error';
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'timeout_error';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = 'network_error';
          }
          // Crear un nuevo error con el mensaje personalizado
          final customError = DioException(
            requestOptions: error.requestOptions,
            type: error.type,
            error: errorMessage,
          );
          handler.next(customError);
        },
      ),
    );
  }

  /// Verifica una cuenta de Valorant
  Future<Account> checkAccount(Account account) async {
    try {
      // Verificar caché primero
      if (config.enableCache) {
        final cached = _getFromCache(account.username);
        if (cached != null) {
          return cached;
        }
      }

      // Obtener token de autenticación
      final authToken = await _getAuthToken(account.username, account.password);
      if (authToken == null) {
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: AppConstants.errorMessages['invalid_credentials'],
          lastChecked: DateTime.now(),
        );
      }

      // Obtener entitlements token
      final entitlementsToken = await _getEntitlementsToken(authToken);
      if (entitlementsToken == null) {
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo entitlements',
          lastChecked: DateTime.now(),
        );
      }

      // Obtener información del jugador
      final playerInfo = await _getPlayerInfo(authToken, entitlementsToken);
      if (playerInfo == null) {
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo información del jugador',
          lastChecked: DateTime.now(),
        );
      }

      // Procesar información del jugador
      final processedAccount = _processPlayerInfo(account, playerInfo);

      // Guardar en caché
      if (config.enableCache) {
        _saveToCache(processedAccount);
      }

      return processedAccount;
    } catch (e) {
      return account.copyWith(
        status: AppConstants.statusError,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Obtiene token de autenticación de Riot
  Future<String?> _getAuthToken(String username, String password) async {
    try {
      final response = await _dio.post(
        '${AppConstants.riotAuthUrl}/api/v1/authentication',
        data: {
          'type': 'auth',
          'username': username,
          'password': password,
          'remember': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['type'] == 'response' &&
            data['response']['parameters'] != null) {
          return data['response']['parameters']['uri']
              .split('access_token=')[1]
              .split('&')[0];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene entitlements token
  Future<String?> _getEntitlementsToken(String authToken) async {
    try {
      final response = await _dio.post(
        '${AppConstants.riotEntitlementsUrl}/api/token/v1',
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200) {
        return response.data['entitlements_token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene información del jugador
  Future<Map<String, dynamic>?> _getPlayerInfo(
    String authToken,
    String entitlementsToken,
  ) async {
    try {
      // Intentar con diferentes regiones
      for (final region in config.regions) {
        try {
          final response = await _dio.get(
            '${AppConstants.valorantApiBase.replaceAll('{region}', region)}/player-account/account',
            options: Options(headers: {
              'Authorization': 'Bearer $authToken',
              'X-Riot-Entitlements-JWT': entitlementsToken,
            }),
          );

          if (response.statusCode == 200) {
            final data = response.data;
            data['region'] = region;
            return data;
          }
        } catch (e) {
          continue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Procesa la información del jugador
  Account _processPlayerInfo(Account account, Map<String, dynamic> playerInfo) {
    final region = playerInfo['region'] ?? 'unknown';
    final level = playerInfo['AccountLevel'] ?? 0;
    final hasSkins =
        playerInfo['skins'] != null && (playerInfo['skins'] as List).isNotEmpty;
    final isBanned = playerInfo['banned'] == true;
    final isLocked = playerInfo['locked'] == true;

    String status = AppConstants.statusValid;
    if (isBanned) {
      status = AppConstants.statusBanned;
    } else if (isLocked) {
      status = AppConstants.statusLocked;
    }

    return account.copyWith(
      status: status,
      region: region,
      level: level,
      hasSkins: hasSkins,
      isBanned: isBanned,
      isLocked: isLocked,
      lastChecked: DateTime.now(),
      additionalData: playerInfo,
    );
  }

  /// Obtiene cuenta del caché
  Account? _getFromCache(String username) {
    final cached = _cache[username];
    if (cached != null) {
      final lastChecked = DateTime.parse(cached['lastChecked']);
      final hoursSinceCheck = DateTime.now().difference(lastChecked).inHours;

      if (hoursSinceCheck < config.cacheDuration) {
        return Account.fromJson(cached);
      } else {
        _cache.remove(username);
      }
    }
    return null;
  }

  /// Guarda cuenta en caché
  void _saveToCache(Account account) {
    if (_cache.length >= config.maxCacheSize) {
      // Eliminar entrada más antigua
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[account.username] = account.toJson();
  }

  /// Limpia el caché
  void clearCache() {
    _cache.clear();
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getCacheStats() {
    return {'size': _cache.length, 'maxSize': config.maxCacheSize};
  }
}
