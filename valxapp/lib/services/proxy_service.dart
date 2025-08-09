import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProxyService {
  static final List<Map<String, dynamic>> _proxyList = [
    // Proxies HTTP gratuitos (estos son ejemplos, necesitarás proxies reales)
    {'host': '103.149.162.194', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.195', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.196', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.197', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.198', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.199', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.200', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.201', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.202', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.203', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.204', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.205', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.206', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.207', 'port': 80, 'type': 'http'},
    {'host': '103.149.162.208', 'port': 80, 'type': 'http'},

    // Proxies SOCKS5 (ejemplos)
    {'host': '185.32.120.242', 'port': 1080, 'type': 'socks5'},
    {'host': '185.32.120.243', 'port': 1080, 'type': 'socks5'},
    {'host': '185.32.120.244', 'port': 1080, 'type': 'socks5'},
    {'host': '185.32.120.245', 'port': 1080, 'type': 'socks5'},
    {'host': '185.32.120.246', 'port': 1080, 'type': 'socks5'},
  ];

  static final List<Map<String, dynamic>> _validatedProxies = [];
  static final Random _random = Random();
  static bool _isValidating = false;

  /// Obtiene un proxy aleatorio validado
  static Map<String, dynamic>? getRandomProxy() {
    if (_validatedProxies.isEmpty) {
      return null;
    }
    return _validatedProxies[_random.nextInt(_validatedProxies.length)];
  }

  /// Valida todos los proxies de la lista
  static Future<void> validateProxies() async {
    if (_isValidating) return;

    _isValidating = true;
    _validatedProxies.clear();

    debugPrint('🔍 Validando ${_proxyList.length} proxies...');

    final List<Future<void>> validationTasks = [];

    for (final proxy in _proxyList) {
      validationTasks.add(_validateSingleProxy(proxy));
    }

    await Future.wait(validationTasks);

    debugPrint(
      '✅ Validación completada: ${_validatedProxies.length}/${_proxyList.length} proxies funcionales',
    );
    _isValidating = false;
  }

  /// Valida un proxy individual
  static Future<void> _validateSingleProxy(Map<String, dynamic> proxy) async {
    try {
      final dio = Dio();

      // Configurar proxy
      dio.options.connectTimeout = Duration(seconds: 10);
      dio.options.receiveTimeout = Duration(seconds: 10);

      // Para HTTP proxies
      if (proxy['type'] == 'http') {
        dio.options.extra['proxy'] = 'http://${proxy['host']}:${proxy['port']}';
      }

      // Probar conectividad con un servicio simple
      final response = await dio.get('https://httpbin.org/ip');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['origin'] != null) {
          proxy['validated'] = true;
          proxy['ip'] = responseData['origin'];
          _validatedProxies.add(proxy);
          debugPrint(
            '✅ Proxy válido: ${proxy['host']}:${proxy['port']} -> IP: ${responseData['origin']}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Proxy inválido: ${proxy['host']}:${proxy['port']} -> Error: $e');
    }
  }

  /// Genera proxies aleatorios ficticios para testing
  static void generateRandomProxies() {
    _proxyList.clear();

    // Rangos de IP comunes para proxies
    final ipRanges = [
      '103.149.162',
      '185.32.120',
      '91.203.67',
      '45.77.55',
      '149.28.128',
      '207.148.22',
      '108.61.201',
      '144.202.126',
    ];

    for (int i = 0; i < 20; i++) {
      final baseIp = ipRanges[_random.nextInt(ipRanges.length)];
      final lastOctet = _random.nextInt(255) + 1;
      final port = _random.nextBool() ? 80 : 8080;
      final type = _random.nextBool() ? 'http' : 'socks5';

      _proxyList.add({
        'host': '$baseIp.$lastOctet',
        'port': port,
        'type': type,
      });
    }

    debugPrint('🎲 Generados ${_proxyList.length} proxies aleatorios para testing');
  }

  /// Configura Dio con un proxy aleatorio
  static void configureProxyForDio(
    Dio dio, {
    Map<String, dynamic>? specificProxy,
  }) {
    final proxy = specificProxy ?? getRandomProxy();

    if (proxy == null) {
      debugPrint('⚠️ No hay proxies disponibles, usando conexión directa');
      return;
    }

    try {
      // Configurar proxy según el tipo
      if (proxy['type'] == 'http') {
        dio.options.extra['proxy'] = 'http://${proxy['host']}:${proxy['port']}';
        debugPrint('🔄 Usando proxy HTTP: ${proxy['host']}:${proxy['port']}');
      } else if (proxy['type'] == 'socks5') {
        // Para SOCKS5, necesitaríamos una implementación específica
        // Por ahora usamos HTTP como fallback
        dio.options.extra['proxy'] = 'http://${proxy['host']}:${proxy['port']}';
        debugPrint(
          '🔄 Usando proxy SOCKS5 (como HTTP): ${proxy['host']}:${proxy['port']}',
        );
      }

      // Agregar timeout específico para proxies
      dio.options.connectTimeout = Duration(seconds: 15);
      dio.options.receiveTimeout = Duration(seconds: 15);
    } catch (e) {
      debugPrint('❌ Error configurando proxy: $e');
    }
  }

  /// Obtiene estadísticas de proxies
  static Map<String, dynamic> getProxyStats() {
    return {
      'total': _proxyList.length,
      'validated': _validatedProxies.length,
      'success_rate': _proxyList.isEmpty
          ? 0.0
          : (_validatedProxies.length / _proxyList.length * 100),
      'is_validating': _isValidating,
    };
  }

  /// Remueve un proxy de la lista de validados si falla
  static void markProxyAsFailed(Map<String, dynamic> proxy) {
    _validatedProxies.removeWhere(
      (p) => p['host'] == proxy['host'] && p['port'] == proxy['port'],
    );
    debugPrint(
      '🚫 Proxy marcado como fallido y removido: ${proxy['host']}:${proxy['port']}',
    );
  }

  /// Agrega proxies personalizados
  static void addCustomProxies(List<Map<String, dynamic>> customProxies) {
    _proxyList.addAll(customProxies);
    debugPrint('➕ Agregados ${customProxies.length} proxies personalizados');
  }

  /// Limpia todos los proxies
  static void clearProxies() {
    _proxyList.clear();
    _validatedProxies.clear();
    debugPrint('🧹 Lista de proxies limpiada');
  }

  /// Carga proxies desde una lista de strings en formato "host:port"
  static void loadProxiesFromStrings(List<String> proxyStrings) {
    for (final proxyString in proxyStrings) {
      final parts = proxyString.split(':');
      if (parts.length == 2) {
        final host = parts[0].trim();
        final port = int.tryParse(parts[1].trim());

        if (port != null) {
          _proxyList.add({
            'host': host,
            'port': port,
            'type': 'http', // Por defecto HTTP
          });
        }
      }
    }
    debugPrint('📥 Cargados ${proxyStrings.length} proxies desde strings');
  }
}
