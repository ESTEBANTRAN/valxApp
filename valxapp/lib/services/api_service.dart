import 'dart:math';
import 'package:dio/dio.dart';
import '../models/account.dart';
import '../models/checker_config.dart';
import '../utils/constants.dart';
import 'proxy_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio _dio;
  final CheckerConfig config;
  final Map<String, dynamic> _cache = {};
  final Random _random = Random();

  // User agents rotativos para evitar detección
  static const List<String> _userAgents = [
    'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 10;;Professional, x64)',
    'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 11;;Professional, x64)',
    'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 10;;Home, x64)',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  ];

  ApiService({required this.config}) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: config.requestTimeout),
        receiveTimeout: Duration(seconds: config.requestTimeout),
        headers: {
          'User-Agent': _userAgents[_random.nextInt(_userAgents.length)],
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
        },
      ),
    );

    // Configurar proxy aleatorio para esta instancia
    ProxyService.configureProxyForDio(_dio);

    // Configurar interceptores para rate limiting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Rotar User-Agent
          options.headers['User-Agent'] =
              _userAgents[_random.nextInt(_userAgents.length)];

          // Rotar proxy para cada request
          ProxyService.configureProxyForDio(_dio);

          // Agregar delay aleatorio más largo para evitar rate limiting
          if (config.enableRandomDelays) {
            final delay = _random.nextInt(5000) + 3000; // 3-8 segundos
            await Future.delayed(Duration(milliseconds: delay));
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Manejar errores de rate limiting
          if (error.response?.statusCode == 429) {
            debugPrint('⚠️ Rate limiting detectado, esperando 10 segundos...');
            await Future.delayed(Duration(seconds: 10));
            // Reintentar la solicitud
            handler.resolve(await _dio.fetch(error.requestOptions));
            return;
          }

          // Manejar otros errores de red
          String errorMessage = 'unknown_error';
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'timeout_error';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = 'network_error';
          }

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

  /// Verifica una cuenta de Valorant usando la API oficial
  Future<Account> checkAccount(Account account) async {
    try {
      // Verificar caché primero
      if (config.enableCache) {
        final cached = _getFromCache(account.username);
        if (cached != null) {
          return cached;
        }
      }

      debugPrint('🔍 Verificando cuenta: ${account.username}');

      // Paso 1: Obtener cookies de sesión
      final cookies = await _getSessionCookies();
      if (cookies == null) {
        debugPrint('❌ Error obteniendo cookies de sesión');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo cookies de sesión',
          lastChecked: DateTime.now(),
        );
      }

      // Paso 2: Autenticar con Riot
      final authData = await _authenticateRiot(
        account.username,
        account.password,
        cookies,
      );
      if (authData == null) {
        debugPrint('❌ Error en autenticación para: ${account.username}');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: AppConstants.errorMessages['invalid_credentials'],
          lastChecked: DateTime.now(),
        );
      }

      // Paso 3: Obtener token de acceso
      final accessToken = await _getAccessToken(authData);
      if (accessToken == null) {
        debugPrint('❌ Error obteniendo token de acceso para: ${account.username}');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo token de acceso',
          lastChecked: DateTime.now(),
        );
      }

      // Paso 4: Obtener entitlements
      final entitlementsToken = await _getEntitlementsToken(accessToken);
      if (entitlementsToken == null) {
        debugPrint('❌ Error obteniendo entitlements para: ${account.username}');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo entitlements',
          lastChecked: DateTime.now(),
        );
      }

      // Paso 5: Obtener información del usuario
      final userInfo = await _getUserInfo(accessToken);
      if (userInfo == null) {
        debugPrint('❌ Error obteniendo información del usuario para: ${account.username}');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo información del usuario',
          lastChecked: DateTime.now(),
        );
      }

      // Paso 6: Determinar región
      final region = await _getUserRegion(accessToken, userInfo['sub']);

      // Paso 7: Obtener información del jugador usando API oficial
      final playerInfo = await _getPlayerInfoOfficial(
        accessToken,
        entitlementsToken,
        region,
        userInfo['sub'],
      );
      if (playerInfo == null) {
        debugPrint('❌ Error obteniendo información del jugador para: ${account.username}');
        return account.copyWith(
          status: AppConstants.statusError,
          errorMessage: 'Error obteniendo información del jugador',
          lastChecked: DateTime.now(),
        );
      }

      // Procesar información del jugador
      final processedAccount = _processPlayerInfo(account, playerInfo, region);

      debugPrint('✅ Cuenta verificada exitosamente: ${account.username} - ${processedAccount.status}');

      // Guardar en caché
      if (config.enableCache) {
        _saveToCache(processedAccount);
      }

      return processedAccount;
    } catch (e) {
      debugPrint('❌ Error general verificando cuenta ${account.username}: $e');
      return account.copyWith(
        status: AppConstants.statusError,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );
    }
  }

  /// Obtiene cookies de sesión iniciales
  Future<Map<String, String>?> _getSessionCookies() async {
    try {
      debugPrint('🍪 Obteniendo cookies de sesión...');
      
      final response = await _dio.post(
        '${AppConstants.riotAuthUrl}/api/v1/authorization',
        data: {
          'client_id': 'play-valorant-web-prod',
          'response_type': 'token id_token',
          'redirect_uri': 'https://playvalorant.com/opt_in',
          'nonce': '1',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('🍪 Status code de cookies: ${response.statusCode}');

      if (response.statusCode == 200) {
        final cookies = <String, String>{};
        if (response.headers.map.containsKey('set-cookie')) {
          final cookieHeaders = response.headers.map['set-cookie']!;
          for (final cookie in cookieHeaders) {
            final parts = cookie.split(';')[0].split('=');
            if (parts.length == 2) {
              cookies[parts[0]] = parts[1];
            }
          }
        }
        debugPrint('✅ Cookies de sesión obtenidas: ${cookies.length} cookies');
        return cookies;
      }
      debugPrint('❌ Error obteniendo cookies: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Excepción obteniendo cookies: $e');
      return null;
    }
  }

  /// Autentica con Riot Games
  Future<Map<String, dynamic>?> _authenticateRiot(
    String username,
    String password,
    Map<String, String> cookies,
  ) async {
    try {
      final cookieString = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');

      debugPrint('🔐 Intentando autenticar: $username');

      final response = await _dio.put(
        '${AppConstants.riotAuthUrl}/api/v1/authorization',
        data: {
          'type': 'auth',
          'username': username,
          'password': password,
          'remember': true,
        },
        options: Options(
          headers: {
            'Cookie': cookieString,
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('🔐 Status code de autenticación: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('🔐 Respuesta de autenticación: ${data['type']}');
        
        if (data['type'] == 'response') {
          debugPrint('✅ Autenticación exitosa');
          return data;
        } else if (data['type'] == 'multifactor') {
          debugPrint('⚠️ Autenticación de dos factores requerida');
          return null;
        } else if (data['type'] == 'auth') {
          debugPrint('⚠️ Error de autenticación: ${data['error']}');
          return null;
        } else {
          debugPrint('⚠️ Tipo de respuesta desconocido: ${data['type']}');
          return null;
        }
      } else {
        debugPrint('❌ Error en autenticación: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Excepción en autenticación: $e');
      return null;
    }
  }

  /// Extrae token de acceso de la respuesta de autenticación
  Future<String?> _getAccessToken(Map<String, dynamic> authData) async {
    try {
      debugPrint('🔑 Extrayendo token de acceso...');
      
      if (authData['response'] == null || authData['response']['parameters'] == null) {
        debugPrint('❌ Estructura de respuesta inválida');
        return null;
      }
      
      final uri = authData['response']['parameters']['uri'] as String?;
      if (uri == null) {
        debugPrint('❌ URI no encontrada en la respuesta');
        return null;
      }
      
      debugPrint('🔑 URI encontrada: ${uri.substring(0, uri.length > 50 ? 50 : uri.length)}...');
      
      if (uri.contains('access_token=')) {
        final tokenStart = uri.indexOf('access_token=') + 13;
        var tokenEnd = uri.indexOf('&', tokenStart);
        if (tokenEnd == -1) {
          tokenEnd = uri.indexOf('#', tokenStart);
        }
        if (tokenEnd == -1) {
          tokenEnd = uri.length;
        }
        final token = uri.substring(tokenStart, tokenEnd);
        debugPrint('✅ Token de acceso obtenido (${token.length} caracteres)');
        return token;
      }
      debugPrint('❌ No se encontró token de acceso en la URI');
      return null;
    } catch (e) {
      debugPrint('❌ Excepción obteniendo token: $e');
      return null;
    }
  }

  /// Obtiene entitlements token
  Future<String?> _getEntitlementsToken(String accessToken) async {
    try {
      debugPrint('🎫 Obteniendo entitlements token...');
      
      final response = await _dio.post(
        '${AppConstants.riotEntitlementsUrl}/api/token/v1',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('🎫 Status code de entitlements: ${response.statusCode}');

      if (response.statusCode == 200) {
        final token = response.data['entitlements_token'];
        if (token != null) {
          debugPrint('✅ Entitlements token obtenido (${token.length} caracteres)');
          return token;
        } else {
          debugPrint('❌ Entitlements token no encontrado en la respuesta');
          return null;
        }
      }
      debugPrint('❌ Error obteniendo entitlements: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Excepción obteniendo entitlements: $e');
      return null;
    }
  }

  /// Obtiene información del usuario
  Future<Map<String, dynamic>?> _getUserInfo(String accessToken) async {
    try {
      debugPrint('👤 Obteniendo información del usuario...');
      
      final response = await _dio.get(
        '${AppConstants.riotAuthUrl}/userinfo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('👤 Status code de userinfo: ${response.statusCode}');

      if (response.statusCode == 200) {
        final userData = response.data;
        if (userData['sub'] != null) {
          debugPrint('✅ Información del usuario obtenida: ${userData['sub']}');
          return userData;
        } else {
          debugPrint('❌ Sub no encontrado en la respuesta del usuario');
          return null;
        }
      }
      debugPrint('❌ Error obteniendo información del usuario: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Excepción obteniendo información del usuario: $e');
      return null;
    }
  }

  /// Determina la región del usuario
  Future<String> _getUserRegion(String accessToken, String userId) async {
    final regions = ['na', 'eu', 'ap', 'br', 'kr', 'latam'];

    debugPrint('🌍 Determinando región para usuario: $userId');

    for (final region in regions) {
      try {
        debugPrint('🌍 Probando región: $region');
        
        final response = await _dio.put(
          'https://pd.$region.a.pvp.net/name-service/v2/players',
          data: [userId],
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'X-Riot-ClientPlatform':
                  'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Región determinada: $region');
          return region;
        } else {
          debugPrint('⚠️ Región $region no válida: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('⚠️ Error probando región $region: $e');
        continue;
      }
    }

    debugPrint('⚠️ No se pudo determinar región, usando NA por defecto');
    return 'na'; // Región por defecto
  }

  /// Obtiene información del jugador usando API oficial de Valorant
  Future<Map<String, dynamic>?> _getPlayerInfoOfficial(
    String accessToken,
    String entitlementsToken,
    String region,
    String userId,
  ) async {
    try {
      debugPrint('🎮 Obteniendo información del jugador para región: $region, usuario: $userId');
      
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'X-Riot-Entitlements-JWT': entitlementsToken,
        'X-Riot-ClientPlatform':
            'ew0KCSJwbGF0Zm9ybVR5cGUiOiAiUEMiLA0KCSJwbGF0Zm9ybU9TIjogIldpbmRvd3MiLA0KCSJwbGF0Zm9ybU9TVmVyc2lvbiI6ICIxMC4wLjE5MDQyLjEuMjU2LjY0Yml0IiwNCgkicGxhdGZvcm1DaGlwc2V0IjogIlVua25vd24iDQp9',
        'Content-Type': 'application/json',
      };

      // Obtener PUUID del usuario
      final puuid = userId;

      // Obtener información del jugador usando API oficial
      final playerResponse = await _dio.get(
        'https://pd.$region.a.pvp.net/player-loadout/v2/$puuid',
        options: Options(headers: headers),
      );

      debugPrint('🎮 Status code de player-loadout: ${playerResponse.statusCode}');

      if (playerResponse.statusCode == 200) {
        final playerData = playerResponse.data;

        // Obtener nivel del jugador
        final levelResponse = await _dio.get(
          'https://pd.$region.a.pvp.net/account-xp/v1/players/$puuid',
          options: Options(headers: headers),
        );

        int level = 1;
        if (levelResponse.statusCode == 200) {
          final levelData = levelResponse.data;
          level = levelData['Progress']?['Level'] ?? 1;
          debugPrint('🎮 Nivel del jugador: $level');
        } else {
          debugPrint('⚠️ Error obteniendo nivel: ${levelResponse.statusCode}');
        }

        // Obtener información de la cuenta
        final accountResponse = await _dio.get(
          'https://pd.$region.a.pvp.net/player-account/account',
          options: Options(headers: headers),
        );

        bool isBanned = false;
        bool isLocked = false;

        if (accountResponse.statusCode == 200) {
          final accountData = accountResponse.data;
          isBanned = accountData['banned'] ?? false;
          isLocked = accountData['locked'] ?? false;
          debugPrint('🎮 Estado de cuenta - Baneada: $isBanned, Bloqueada: $isLocked');
        } else {
          debugPrint('⚠️ Error obteniendo información de cuenta: ${accountResponse.statusCode}');
        }

        // Obtener skins
        List<String> skins = [];
        if (playerData['Guns'] != null) {
          for (final gun in playerData['Guns']) {
            if (gun['Skins'] != null && gun['Skins'].isNotEmpty) {
              final skinId = gun['Skins'][0]['ID'];
              skins.add(skinId);
            }
          }
        }

        // Combinar información
        final playerInfo = {
          'region': region,
          'userId': puuid,
          'AccountLevel': level,
          'skins': skins,
          'banned': isBanned,
          'locked': isLocked,
          'additionalData': {'profile': playerData, 'level': level},
        };

        debugPrint('✅ Información del jugador obtenida: Nivel $level, ${skins.length} skins');
        return playerInfo;
      }
      debugPrint('❌ Error obteniendo información del jugador: ${playerResponse.statusCode} - ${playerResponse.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Excepción obteniendo información del jugador: $e');
      return null;
    }
  }

  /// Procesa la información del jugador
  Account _processPlayerInfo(
    Account account,
    Map<String, dynamic> playerInfo,
    String region,
  ) {
    final level = playerInfo['AccountLevel'] ?? 1;
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
      additionalData: playerInfo['additionalData'],
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
