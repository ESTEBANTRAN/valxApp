import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'proxy_service.dart';

class ProxyProvider {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  /// URLs de proveedores de proxies gratuitos
  static const List<String> _proxyProviders = [
    'https://api.proxyscrape.com/v2/?request=get&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all',
    'https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt',
    'https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt',
    'https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt',
    'https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt',
  ];

  /// Descarga proxies de proveedores públicos
  static Future<List<Map<String, dynamic>>> downloadProxies() async {
    final List<Map<String, dynamic>> allProxies = [];

    debugPrint('🌐 Descargando proxies de ${_proxyProviders.length} proveedores...');

    for (int i = 0; i < _proxyProviders.length; i++) {
      final provider = _proxyProviders[i];
      try {
        debugPrint(
          '📥 Descargando desde proveedor ${i + 1}/${_proxyProviders.length}...',
        );

        final response = await _dio.get(provider);

        if (response.statusCode == 200) {
          final proxies = _parseProxyList(response.data.toString());
          allProxies.addAll(proxies);
          debugPrint('✅ Obtenidos ${proxies.length} proxies del proveedor ${i + 1}');
        }

        // Delay entre requests para ser respetuoso
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        debugPrint('❌ Error descargando desde proveedor ${i + 1}: $e');
      }
    }

    // Eliminar duplicados
    final uniqueProxies = _removeDuplicates(allProxies);
    debugPrint('🎯 Total de proxies únicos obtenidos: ${uniqueProxies.length}');

    return uniqueProxies;
  }

  /// Parsea una lista de proxies en formato texto
  static List<Map<String, dynamic>> _parseProxyList(String content) {
    final List<Map<String, dynamic>> proxies = [];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Formato: IP:PORT
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final host = parts[0].trim();
        final port = int.tryParse(parts[1].trim());

        if (port != null && _isValidIP(host)) {
          proxies.add({
            'host': host,
            'port': port,
            'type': 'http',
            'source': 'downloaded',
          });
        }
      }
    }

    return proxies;
  }

  /// Valida si una cadena es una IP válida
  static bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Elimina proxies duplicados
  static List<Map<String, dynamic>> _removeDuplicates(
    List<Map<String, dynamic>> proxies,
  ) {
    final Set<String> seen = {};
    final List<Map<String, dynamic>> unique = [];

    for (final proxy in proxies) {
      final key = '${proxy['host']}:${proxy['port']}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(proxy);
      }
    }

    return unique;
  }

  /// Descarga y configura proxies automáticamente
  static Future<void> setupProxiesAutomatically() async {
    try {
      debugPrint('🚀 Configurando proxies automáticamente...');

      // Limpiar proxies existentes
      ProxyService.clearProxies();

      // Generar algunos proxies de prueba primero
      ProxyService.generateRandomProxies();

      // Intentar descargar proxies reales
      final downloadedProxies = await downloadProxies();

      if (downloadedProxies.isNotEmpty) {
        // Tomar una muestra aleatoria para evitar sobrecargar
        final sampleSize = downloadedProxies.length > 50
            ? 50
            : downloadedProxies.length;
        downloadedProxies.shuffle();
        final sample = downloadedProxies.take(sampleSize).toList();

        ProxyService.addCustomProxies(sample);
        debugPrint('➕ Agregados ${sample.length} proxies descargados');
      }

      // Validar todos los proxies
      await ProxyService.validateProxies();

      final stats = ProxyService.getProxyStats();
      debugPrint(
        '✅ Configuración automática completada: ${stats['validated']}/${stats['total']} proxies válidos',
      );
    } catch (e) {
      debugPrint('❌ Error en configuración automática: $e');

      // Fallback: usar proxies generados aleatoriamente
      debugPrint('🔄 Usando fallback: proxies generados aleatoriamente');
      ProxyService.clearProxies();
      ProxyService.generateRandomProxies();
      await ProxyService.validateProxies();
    }
  }

  /// Genera proxies premium simulados (para testing)
  static List<Map<String, dynamic>> generatePremiumProxies() {
    return [
      // Proxies premium simulados con alta confiabilidad
      {'host': '198.12.254.161', 'port': 3128, 'type': 'http', 'premium': true},
      {'host': '149.28.128.146', 'port': 3128, 'type': 'http', 'premium': true},
      {'host': '45.77.55.173', 'port': 8080, 'type': 'http', 'premium': true},
      {'host': '207.148.22.139', 'port': 8080, 'type': 'http', 'premium': true},
      {'host': '108.61.201.107', 'port': 3128, 'type': 'http', 'premium': true},
      {'host': '144.202.126.24', 'port': 8080, 'type': 'http', 'premium': true},
      {
        'host': '139.180.140.254',
        'port': 8080,
        'type': 'http',
        'premium': true,
      },
      {'host': '167.99.83.205', 'port': 8080, 'type': 'http', 'premium': true},
      {'host': '134.209.29.120', 'port': 8080, 'type': 'http', 'premium': true},
      {
        'host': '178.128.109.226',
        'port': 8080,
        'type': 'http',
        'premium': true,
      },
    ];
  }

  /// Configura proxies de alta calidad
  static Future<void> setupHighQualityProxies() async {
    try {
      debugPrint('💎 Configurando proxies de alta calidad...');

      ProxyService.clearProxies();

      // Agregar proxies premium simulados
      final premiumProxies = generatePremiumProxies();
      ProxyService.addCustomProxies(premiumProxies);

      // Validar proxies
      await ProxyService.validateProxies();

      final stats = ProxyService.getProxyStats();
      debugPrint(
        '✅ Proxies de alta calidad configurados: ${stats['validated']}/${stats['total']} válidos',
      );
    } catch (e) {
      debugPrint('❌ Error configurando proxies de alta calidad: $e');
    }
  }

  /// Obtiene estadísticas de descarga
  static Map<String, dynamic> getDownloadStats() {
    return {
      'providers': _proxyProviders.length,
      'last_download': DateTime.now().toIso8601String(),
      'proxy_stats': ProxyService.getProxyStats(),
    };
  }
}
