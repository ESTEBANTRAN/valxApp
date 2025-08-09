import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/checker_config.dart';
import '../services/api_service.dart';
import '../services/proxy_service.dart';
import '../services/proxy_provider.dart';
import '../utils/constants.dart';

class CheckerProvider extends ChangeNotifier {
  // Estado del checker
  bool _isRunning = false;
  bool _isPaused = false;
  int _totalAccounts = 0;
  int _checkedAccounts = 0;

  // Nuevas estadísticas principales (sin "error")
  int _validAccountsCount = 0;
  int _bannedAccountsCount = 0;
  int _twoFactorAccountsCount = 0;
  int _invalidCredentialsCount = 0;

  // Estadísticas en tiempo real como ValX original
  // Regiones
  int _euRegionCount = 0;
  int _naRegionCount = 0;
  int _apRegionCount = 0;
  int _krRegionCount = 0;
  int _latamRegionCount = 0;
  int _brRegionCount = 0;

  // Niveles
  int _level1To10Count = 0;
  int _level10To20Count = 0;
  int _level20To30Count = 0;
  int _level30To40Count = 0;
  int _level40To50Count = 0;
  int _level50To100Count = 0;
  int _level100PlusCount = 0;
  int _levelLockedCount = 0;

  // Skins
  int _noSkinsCount = 0;
  int _skinnedCount = 0;
  int _skins1To10Count = 0;
  int _skins10To20Count = 0;
  int _skins20To30Count = 0;
  int _skins30To40Count = 0;
  int _skins40To50Count = 0;
  int _skins50To100Count = 0;
  int _skins100PlusCount = 0;

  // Listas de cuentas
  final List<Account> _accounts = [];
  final List<Account> _validAccountsList = [];
  final List<Account> _bannedAccountsList = [];
  final List<Account> _twoFactorAccountsList = [];
  final List<Account> _invalidCredentialsList = [];

  // Configuración
  CheckerConfig _config = const CheckerConfig();
  // Estadísticas detalladas
  final Map<String, int> _regionStats = {};
  final Map<String, int> _levelStats = {};
  final Map<String, int> _skinStats = {};

  // Proxies
  final List<String> _proxies = [];

  // API Service
  late ApiService _apiService;

  // Stream controllers
  final StreamController<Account> _accountCheckedController =
      StreamController<Account>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _statsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get totalAccounts => _totalAccounts;
  int get checkedAccounts => _checkedAccounts;

  // Nuevos getters para estadísticas principales
  int get validAccountsCount => _validAccountsCount;
  int get bannedAccountsCount => _bannedAccountsCount;
  int get twoFactorAccountsCount => _twoFactorAccountsCount;
  int get invalidCredentialsCount => _invalidCredentialsCount;

  // Getters para estadísticas en tiempo real
  int get euRegionCount => _euRegionCount;
  int get naRegionCount => _naRegionCount;
  int get apRegionCount => _apRegionCount;
  int get krRegionCount => _krRegionCount;
  int get latamRegionCount => _latamRegionCount;
  int get brRegionCount => _brRegionCount;

  int get level1To10Count => _level1To10Count;
  int get level10To20Count => _level10To20Count;
  int get level20To30Count => _level20To30Count;
  int get level30To40Count => _level30To40Count;
  int get level40To50Count => _level40To50Count;
  int get level50To100Count => _level50To100Count;
  int get level100PlusCount => _level100PlusCount;
  int get levelLockedCount => _levelLockedCount;

  int get noSkinsCount => _noSkinsCount;
  int get skinnedCount => _skinnedCount;
  int get skins1To10Count => _skins1To10Count;
  int get skins10To20Count => _skins10To20Count;
  int get skins20To30Count => _skins20To30Count;
  int get skins30To40Count => _skins30To40Count;
  int get skins40To50Count => _skins40To50Count;
  int get skins50To100Count => _skins50To100Count;
  int get skins100PlusCount => _skins100PlusCount;

  // Getters para estadísticas detalladas
  Map<String, int> get regionStats => _regionStats;
  Map<String, int> get levelStats => _levelStats;
  Map<String, int> get skinStats => _skinStats;

  List<Account> get accounts => _accounts;
  List<Account> get validAccountsList => _validAccountsList;
  List<Account> get bannedAccountsList => _bannedAccountsList;
  List<Account> get twoFactorAccountsList => _twoFactorAccountsList;
  List<Account> get invalidCredentialsList => _invalidCredentialsList;

  CheckerConfig get config => _config;

  Stream<Account> get accountCheckedStream => _accountCheckedController.stream;
  Stream<String> get logStream => _logController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  CheckerProvider() {
    _loadConfig();
    _initializeProxies();
  }

  /// Inicializa el sistema de proxies
  void _initializeProxies() async {
    try {
      _log('Inicializando sistema de proxies...');

      // Configurar proxies automáticamente (descarga de proveedores)
      await ProxyProvider.setupProxiesAutomatically();

      final stats = ProxyService.getProxyStats();
      _log(
        'Proxies inicializados: ${stats['validated']}/${stats['total']} válidos (${stats['success_rate'].toStringAsFixed(1)}%)',
      );

      if (stats['validated'] == 0) {
        _log('⚠️ No se encontraron proxies válidos, usando conexión directa');
      }
    } catch (e) {
      _log('Error inicializando proxies: $e');
      _log('🔄 Intentando configuración de respaldo...');

      try {
        // Fallback: proxies de alta calidad simulados
        await ProxyProvider.setupHighQualityProxies();
        final stats = ProxyService.getProxyStats();
        _log(
          'Proxies de respaldo: ${stats['validated']}/${stats['total']} válidos',
        );
      } catch (fallbackError) {
        _log('Error en configuración de respaldo: $fallbackError');
      }
    }
  }

  /// Carga la configuración desde SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('checker_config');
      if (configJson != null) {
        final configMap = json.decode(configJson);
        _config = CheckerConfig.fromJson(configMap);
      }
      _apiService = ApiService(_config, _proxies);
      notifyListeners();
    } catch (e) {
      _log('Error cargando configuración: $e');
    }
  }

  /// Guarda la configuración en SharedPreferences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('checker_config', json.encode(_config.toJson()));
    } catch (e) {
      _log('Error guardando configuración: $e');
    }
  }

  /// Actualiza la configuración
  Future<void> updateConfig(CheckerConfig newConfig) async {
    _config = newConfig;
    _apiService = ApiService(_config, _proxies);
    await _saveConfig();
    notifyListeners();
  }

  /// Carga cuentas desde un archivo de texto
  Future<void> loadAccountsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado');
      }

      final content = await file.readAsString();
      final lines = content.split('\n');

      _accounts.clear();

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
          if (trimmedLine.contains(':')) {
            final parts = trimmedLine.split(':');
            if (parts.length >= 2) {
              _accounts.add(
                Account(username: parts[0].trim(), password: parts[1].trim()),
              );
            }
          }
        }
      }

      _totalAccounts = _accounts.length;
      _log('Cargadas $_totalAccounts cuentas desde $filePath');
      notifyListeners();
    } catch (e) {
      _log('Error cargando cuentas: $e');
      rethrow;
    }
  }

  /// Carga cuentas desde texto
  Future<void> loadAccountsFromText(String text) async {
    try {
      final lines = text.split('\n');

      _accounts.clear();

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
          if (trimmedLine.contains(':')) {
            final parts = trimmedLine.split(':');
            if (parts.length >= 2) {
              _accounts.add(
                Account(username: parts[0].trim(), password: parts[1].trim()),
              );
            }
          }
        }
      }

      _totalAccounts = _accounts.length;
      _log('Cargadas $_totalAccounts cuentas desde texto');
      notifyListeners();
    } catch (e) {
      _log('Error cargando cuentas: $e');
      rethrow;
    }
  }

  /// Inicia el proceso de verificación
  Future<void> startChecking() async {
    if (_isRunning || _accounts.isEmpty) return;

    _isRunning = true;
    _isPaused = false;
    _resetCounters();
    _log('Iniciando verificación de $_totalAccounts cuentas...');
    notifyListeners();

    try {
      // Procesar cuentas en lotes
      final batches = _createBatches(_accounts, _config.maxConcurrentRequests);

      for (final batch in batches) {
        if (!_isRunning || _isPaused) break;

        await _processBatch(batch);

        // Delay entre lotes para evitar rate limiting
        if (batches.indexOf(batch) < batches.length - 1) {
          await Future.delayed(Duration(seconds: _config.retryDelay));
        }
      }

      if (_isRunning) {
        _log('Verificación completada. Resultados guardados.');
        await _saveResults();
      }
    } catch (e) {
      _log('Error durante la verificación: $e');
    } finally {
      _isRunning = false;
      _isPaused = false;
      notifyListeners();
    }
  }

  /// Pausa el proceso de verificación
  void pauseChecking() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      _log('Verificación pausada');
      notifyListeners();
    }
  }

  /// Reanuda el proceso de verificación
  void resumeChecking() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      _log('Verificación reanudada');
      notifyListeners();
    }
  }

  /// Detiene el proceso de verificación
  void stopChecking() {
    if (_isRunning) {
      _isRunning = false;
      _isPaused = false;
      _log('Verificación detenida');
      notifyListeners();
    }
  }

  /// Procesa un lote de cuentas
  Future<void> _processBatch(List<Account> batch) async {
    final futures = batch.map((account) => _checkAccount(account));
    await Future.wait(futures);
  }

  /// Verifica una cuenta individual
  Future<void> _checkAccount(Account account) async {
    if (!_isRunning || _isPaused) return;

    try {
      final checkedAccount = await _apiService.checkAccount(account.username, account.password);

      _checkedAccounts++;
      _accountCheckedController.add(checkedAccount);

      // Clasificar cuenta según su estado
      _classifyAccount(checkedAccount);

      _log('Verificada: ${account.username} - ${checkedAccount.status}');
    } catch (e) {
      _checkedAccounts++;

      final errorAccount = account.copyWith(
        status: AppConstants.statusInvalidCredentials,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );

      _accountCheckedController.add(errorAccount);

      // Clasificar cuenta según su estado
      _classifyAccount(errorAccount);

      _log('Error verificando ${account.username}: $e');
    }
  }

  /// Clasifica una cuenta según su estado
  void _classifyAccount(Account account) {
    switch (account.status) {
      case AppConstants.statusValid:
        _validAccountsCount++;
        _validAccountsList.add(account);
        _updateDetailedStats(account);
        break;
      case AppConstants.statusBanned:
        _bannedAccountsCount++;
        _bannedAccountsList.add(account);
        _updateDetailedStats(account);
        break;
      case AppConstants.statusTwoFactor:
        _twoFactorAccountsCount++;
        _twoFactorAccountsList.add(account);
        break;
      case AppConstants.statusInvalidCredentials:
        _invalidCredentialsCount++;
        _invalidCredentialsList.add(account);
        break;
      case AppConstants.statusLocked:
        _levelLockedCount++;
        break;
      case AppConstants.statusError:
        _invalidCredentialsCount++;
        _invalidCredentialsList.add(account);
        break;
    }

    // Emitir estadísticas actualizadas en tiempo real
    _emitStatsUpdate();
  }

  /// Actualiza estadísticas detalladas en tiempo real
  void _updateDetailedStats(Account account) {
    // Actualizar estadísticas de región
    if (account.region != null) {
      switch (account.region!.toLowerCase()) {
        case 'eu':
          _euRegionCount++;
          break;
        case 'na':
          _naRegionCount++;
          break;
        case 'ap':
          _apRegionCount++;
          break;
        case 'kr':
          _krRegionCount++;
          break;
        case 'latam':
          _latamRegionCount++;
          break;
        case 'br':
          _brRegionCount++;
          break;
      }
    }

    // Actualizar estadísticas de nivel
    if (account.level != null) {
      final level = account.level!;
      if (level == 0) {
        _levelLockedCount++;
      } else if (level <= 10) {
        _level1To10Count++;
      } else if (level <= 20) {
        _level10To20Count++;
      } else if (level <= 30) {
        _level20To30Count++;
      } else if (level <= 40) {
        _level30To40Count++;
      } else if (level <= 50) {
        _level40To50Count++;
      } else if (level <= 100) {
        _level50To100Count++;
      } else {
        _level100PlusCount++;
      }
    }

    // Actualizar estadísticas de skins
    if (account.hasSkins == true) {
      _skinnedCount++;
      final skinCount = account.skinCount ?? 0;
      if (skinCount <= 10) {
        _skins1To10Count++;
      } else if (skinCount <= 20) {
        _skins10To20Count++;
      } else if (skinCount <= 30) {
        _skins20To30Count++;
      } else if (skinCount <= 40) {
        _skins30To40Count++;
      } else if (skinCount <= 50) {
        _skins40To50Count++;
      } else if (skinCount <= 100) {
        _skins50To100Count++;
      } else {
        _skins100PlusCount++;
      }
    } else {
      _noSkinsCount++;
    }
  }

  /// Emite actualización de estadísticas en tiempo real
  void _emitStatsUpdate() {
    final stats = {
      'validAccounts': _validAccountsCount,
      'bannedAccounts': _bannedAccountsCount,
      'twoFactorAccounts': _twoFactorAccountsCount,
      'invalidCredentials': _invalidCredentialsCount,

      // Regiones
      'euRegion': _euRegionCount,
      'naRegion': _naRegionCount,
      'apRegion': _apRegionCount,
      'krRegion': _krRegionCount,
      'latamRegion': _latamRegionCount,
      'brRegion': _brRegionCount,

      // Niveles
      'level1To10': _level1To10Count,
      'level10To20': _level10To20Count,
      'level20To30': _level20To30Count,
      'level30To40': _level30To40Count,
      'level40To50': _level40To50Count,
      'level50To100': _level50To100Count,
      'level100Plus': _level100PlusCount,
      'levelLocked': _levelLockedCount,

      // Skins
      'noSkins': _noSkinsCount,
      'skinned': _skinnedCount,
      'skins1To10': _skins1To10Count,
      'skins10To20': _skins10To20Count,
      'skins20To30': _skins20To30Count,
      'skins30To40': _skins30To40Count,
      'skins40To50': _skins40To50Count,
      'skins50To100': _skins50To100Count,
      'skins100Plus': _skins100PlusCount,

      'totalAccounts': _totalAccounts,
      'checkedAccounts': _checkedAccounts,
    };

    _statsController.add(stats);
  }

  /// Crea lotes de cuentas
  List<List<Account>> _createBatches(List<Account> accounts, int batchSize) {
    final batches = <List<Account>>[];
    for (int i = 0; i < accounts.length; i += batchSize) {
      final end = (i + batchSize < accounts.length)
          ? i + batchSize
          : accounts.length;
      batches.add(accounts.sublist(i, end));
    }
    return batches;
  }

  /// Reinicia los contadores
  void _resetCounters() {
    _checkedAccounts = 0;
    _validAccountsCount = 0;
    _bannedAccountsCount = 0;
    _twoFactorAccountsCount = 0;
    _invalidCredentialsCount = 0;

    // Reiniciar estadísticas de regiones
    _euRegionCount = 0;
    _naRegionCount = 0;
    _apRegionCount = 0;
    _krRegionCount = 0;
    _latamRegionCount = 0;
    _brRegionCount = 0;

    // Reiniciar estadísticas de niveles
    _level1To10Count = 0;
    _level10To20Count = 0;
    _level20To30Count = 0;
    _level30To40Count = 0;
    _level40To50Count = 0;
    _level50To100Count = 0;
    _level100PlusCount = 0;
    _levelLockedCount = 0;

    // Reiniciar estadísticas de skins
    _noSkinsCount = 0;
    _skinnedCount = 0;
    _skins1To10Count = 0;
    _skins10To20Count = 0;
    _skins20To30Count = 0;
    _skins30To40Count = 0;
    _skins40To50Count = 0;
    _skins50To100Count = 0;
    _skins100PlusCount = 0;

    _validAccountsList.clear();
    _bannedAccountsList.clear();
    _twoFactorAccountsList.clear();
    _invalidCredentialsList.clear();
  }

  /// Guarda los resultados
  Future<void> _saveResults() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${directory.path}/checker_results');
      if (!await resultsDir.exists()) {
        await resultsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final resultsFile = File('${resultsDir.path}/results_$timestamp.json');

      final results = {
        'timestamp': DateTime.now().toIso8601String(),
        'totalAccounts': _totalAccounts,
        'checkedAccounts': _checkedAccounts,
        'validAccounts': _validAccountsCount,
        'bannedAccounts': _bannedAccountsCount,
        'twoFactorAccounts': _twoFactorAccountsCount,
        'invalidCredentials': _invalidCredentialsCount,
        'validAccountsList': _validAccountsList.map((a) => a.toJson()).toList(),
        'bannedAccountsList': _bannedAccountsList
            .map((a) => a.toJson())
            .toList(),
        'twoFactorAccountsList': _twoFactorAccountsList
            .map((a) => a.toJson())
            .toList(),
        'invalidCredentialsList': _invalidCredentialsList
            .map((a) => a.toJson())
            .toList(),
      };

      await resultsFile.writeAsString(json.encode(results));
      _log('Resultados guardados en: ${resultsFile.path}');
    } catch (e) {
      _log('Error guardando resultados: $e');
    }
  }

  /// Limpia todas las cuentas
  void clearAccounts() {
    _accounts.clear();
    _totalAccounts = 0;
    _resetCounters();
    _log('Cuentas limpiadas');
    notifyListeners();
  }

  /// Limpia el caché
  void clearCache() {
    // El nuevo API service no tiene caché, pero mantenemos el método por compatibilidad
    _log('Caché limpiado');
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getCacheStats() {
    // El nuevo API service no tiene caché, pero mantenemos el método por compatibilidad
    return {'size': 0, 'maxSize': 0};
  }

  /// Agrega un mensaje al log
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    _logController.add(logMessage);
    if (kDebugMode) {
      print(logMessage);
    }
  }

  @override
  void dispose() {
    _accountCheckedController.close();
    _logController.close();
    _statsController.close();
    super.dispose();
  }
}
