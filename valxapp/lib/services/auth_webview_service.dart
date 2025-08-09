import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWebViewService {
  static const String _prefsKeyAccessToken = 'riot_access_token';
  static const String _prefsKeyIdToken = 'riot_id_token';
  static const String _prefsKeyEntitlements = 'riot_entitlements';
  static const String _prefsKeyUserInfo = 'riot_user_info';
  static const String _prefsKeyExpiresAt = 'riot_expires_at';

  // URLs del launcher oficial
  static const String _authUrl = 'https://auth.riotgames.com/login';
  static const String _redirectUrl = 'http://localhost/redirect';

  late WebViewController _controller;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _idToken;
  String? _entitlementsToken;
  Map<String, dynamic>? _userInfo;

  // Callback para notificar cuando la autenticación se complete
  Function(bool success, String? error)? _onAuthComplete;

  WebViewController get controller => _controller;

  bool get isAuthenticated => _isAuthenticated;

  String? get accessToken => _accessToken;
  String? get idToken => _idToken;
  String? get entitlementsToken => _entitlementsToken;
  Map<String, dynamic>? get userInfo => _userInfo;

  Future<void> initialize() async {
    // Cargar tokens guardados
    await _loadSavedTokens();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigation(request);
          },
          onPageFinished: (String url) {
            _handlePageFinished(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(_authUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    debugPrint('WebView Navigation: ${request.url}');
    
    // Interceptar la redirección con tokens
    if (request.url.startsWith(_redirectUrl)) {
      _extractTokensFromUrl(request.url);
      return NavigationDecision.prevent;
    }
    
    return NavigationDecision.navigate;
  }

  void _handlePageFinished(String url) {
    debugPrint('WebView Page Finished: $url');
    
    // Detectar si estamos en la página de login
    if (url.contains('auth.riotgames.com/login')) {
      _injectLoginScript();
    }
  }

  void _injectLoginScript() {
    // Script para interceptar el formulario de login
    const script = '''
      (function() {
        const form = document.querySelector('form');
        if (form) {
          form.addEventListener('submit', function(e) {
            console.log('Login form submitted');
          });
        }
        
        // Observar cambios en la URL para detectar redirecciones
        let currentUrl = window.location.href;
        const observer = new MutationObserver(function() {
          if (window.location.href !== currentUrl) {
            currentUrl = window.location.href;
            console.log('URL changed to: ' + currentUrl);
          }
        });
        observer.observe(document.body, { childList: true, subtree: true });
      })();
    ''';
    
    _controller.runJavaScript(script);
  }

  void _extractTokensFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final fragment = uri.fragment;
      
      if (fragment.isNotEmpty) {
        final params = Uri.splitQueryString(fragment);
        
        _accessToken = params['access_token'];
        _idToken = params['id_token'];
        
        if (_accessToken != null && _idToken != null) {
          debugPrint('Tokens extraídos exitosamente');
          _isAuthenticated = true;
          _saveTokens();
          _getEntitlements();
          _getUserInfo();
          _onAuthComplete?.call(true, null);
        } else {
          debugPrint('Error: Tokens no encontrados en la URL');
          _onAuthComplete?.call(false, 'Tokens no encontrados');
        }
      } else {
        debugPrint('Error: Fragmento vacío en la URL');
        _onAuthComplete?.call(false, 'URL de redirección inválida');
      }
    } catch (e) {
      debugPrint('Error extrayendo tokens: $e');
      _onAuthComplete?.call(false, 'Error extrayendo tokens: $e');
    }
  }

  Future<void> _getEntitlements() async {
    if (_accessToken == null) return;
    
    try {
      final response = await _makeEntitlementsRequest();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        _entitlementsToken = data['entitlements_token'];
        await _saveTokens();
        debugPrint('Entitlements obtenidos exitosamente');
      } else {
        debugPrint('Error obteniendo entitlements: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en _getEntitlements: $e');
    }
  }

  Future<HttpClientResponse> _makeEntitlementsRequest() async {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('https://entitlements.auth.riotgames.com/api/token/v1'));
    
    request.headers.set('Authorization', 'Bearer $_accessToken');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('User-Agent', 'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 10;;Professional, x64)');
    request.headers.set('X-Riot-ClientPlatform', _clientPlatformB64());
    request.headers.set('X-Riot-ClientVersion', 'release-10.0-ship');
    
    request.write('{}');
    return await request.close();
  }

  Future<void> _getUserInfo() async {
    if (_accessToken == null) return;
    
    try {
      final response = await _makeUserInfoRequest();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        _userInfo = data;
        await _saveTokens();
        debugPrint('Información de usuario obtenida exitosamente');
      } else {
        debugPrint('Error obteniendo información de usuario: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en _getUserInfo: $e');
    }
  }

  Future<HttpClientResponse> _makeUserInfoRequest() async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://auth.riotgames.com/userinfo'));
    
    request.headers.set('Authorization', 'Bearer $_accessToken');
    request.headers.set('User-Agent', 'RiotClient/58.0.0.6400298.4552318 rso-auth (Windows; 10;;Professional, x64)');
    request.headers.set('X-Riot-ClientPlatform', _clientPlatformB64());
    request.headers.set('X-Riot-ClientVersion', 'release-10.0-ship');
    
    return await request.close();
  }

  String _clientPlatformB64() {
    const platform = {
      "platformType": "PC",
      "platformOS": "Windows",
      "platformOSVersion": "10.0.19045.1.256.64bit",
      "platformChipset": "Unknown"
    };
    return base64.encode(utf8.encode(json.encode(platform)));
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_accessToken != null) {
      await prefs.setString(_prefsKeyAccessToken, _accessToken!);
    }
    if (_idToken != null) {
      await prefs.setString(_prefsKeyIdToken, _idToken!);
    }
    if (_entitlementsToken != null) {
      await prefs.setString(_prefsKeyEntitlements, _entitlementsToken!);
    }
    if (_userInfo != null) {
      await prefs.setString(_prefsKeyUserInfo, json.encode(_userInfo!));
    }
    
    // Guardar tiempo de expiración (24 horas desde ahora)
    final expiresAt = DateTime.now().add(Duration(hours: 24));
    await prefs.setString(_prefsKeyExpiresAt, expiresAt.toIso8601String());
  }

  Future<void> _loadSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    _accessToken = prefs.getString(_prefsKeyAccessToken);
    _idToken = prefs.getString(_prefsKeyIdToken);
    _entitlementsToken = prefs.getString(_prefsKeyEntitlements);
    
    final userInfoStr = prefs.getString(_prefsKeyUserInfo);
    if (userInfoStr != null) {
      _userInfo = json.decode(userInfoStr);
    }
    
    // Verificar si los tokens no han expirado
    final expiresAtStr = prefs.getString(_prefsKeyExpiresAt);
    if (expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isBefore(expiresAt) && _accessToken != null) {
        _isAuthenticated = true;
        debugPrint('Tokens cargados desde almacenamiento');
      } else {
        // Tokens expirados, limpiar
        await _clearTokens();
      }
    }
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyAccessToken);
    await prefs.remove(_prefsKeyIdToken);
    await prefs.remove(_prefsKeyEntitlements);
    await prefs.remove(_prefsKeyUserInfo);
    await prefs.remove(_prefsKeyExpiresAt);
    
    _accessToken = null;
    _idToken = null;
    _entitlementsToken = null;
    _userInfo = null;
    _isAuthenticated = false;
  }

  void setAuthCallback(Function(bool success, String? error) callback) {
    _onAuthComplete = callback;
  }

  Future<void> logout() async {
    await _clearTokens();
    _controller.loadRequest(Uri.parse(_authUrl));
  }

  void dispose() {
    // No es necesario cerrar el WebViewController aquí
  }
}
