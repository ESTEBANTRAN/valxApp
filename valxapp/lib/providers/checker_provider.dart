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
  int _validAccountsCount = 0;
  int _bannedAccountsCount = 0;
  int _lockedAccountsCount = 0;
  int _errorAccountsCount = 0;

  // Listas de cuentas
  final List<Account> _accounts = [];
  final List<Account> _validAccountsList = [];
  final List<Account> _bannedAccountsList = [];
  final List<Account> _lockedAccountsList = [];
  final List<Account> _errorAccountsList = [];

  // Configuración
  CheckerConfig _config = const CheckerConfig();
  ApiService? _apiService;

  // Stream controllers
  final StreamController<Account> _accountCheckedController =
      StreamController<Account>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  // Getters
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get totalAccounts => _totalAccounts;
  int get checkedAccounts => _checkedAccounts;
  int get validAccountsCount => _validAccountsCount;
  int get bannedAccountsCount => _bannedAccountsCount;
  int get lockedAccountsCount => _lockedAccountsCount;
  int get errorAccountsCount => _errorAccountsCount;

  List<Account> get accounts => _accounts;
  List<Account> get validAccountsList => _validAccountsList;
  List<Account> get bannedAccountsList => _bannedAccountsList;
  List<Account> get lockedAccountsList => _lockedAccountsList;
  List<Account> get errorAccountsList => _errorAccountsList;

  CheckerConfig get config => _config;

  Stream<Account> get accountCheckedStream => _accountCheckedController.stream;
  Stream<String> get logStream => _logController.stream;

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
      _apiService = ApiService(config: _config);
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
    _apiService = ApiService(config: _config);
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
      final checkedAccount = await _apiService!.checkAccount(account);

      _checkedAccounts++;
      _accountCheckedController.add(checkedAccount);

      // Clasificar cuenta según su estado
      _classifyAccount(checkedAccount);

      _log('Verificada: ${account.username} - ${checkedAccount.status}');
      notifyListeners();
    } catch (e) {
      _checkedAccounts++;
      _errorAccountsCount++;

      final errorAccount = account.copyWith(
        status: AppConstants.statusError,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      );

      _errorAccountsList.add(errorAccount);
      _accountCheckedController.add(errorAccount);

      _log('Error verificando ${account.username}: $e');
      notifyListeners();
    }
  }

  /// Clasifica una cuenta según su estado
  void _classifyAccount(Account account) {
    switch (account.status) {
      case AppConstants.statusValid:
        _validAccountsCount++;
        _validAccountsList.add(account);
        break;
      case AppConstants.statusBanned:
        _bannedAccountsCount++;
        _bannedAccountsList.add(account);
        break;
      case AppConstants.statusLocked:
        _lockedAccountsCount++;
        _lockedAccountsList.add(account);
        break;
      case AppConstants.statusError:
        _errorAccountsCount++;
        _errorAccountsList.add(account);
        break;
    }
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
    _lockedAccountsCount = 0;
    _errorAccountsCount = 0;

    _validAccountsList.clear();
    _bannedAccountsList.clear();
    _lockedAccountsList.clear();
    _errorAccountsList.clear();
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
        'lockedAccounts': _lockedAccountsCount,
        'errorAccounts': _errorAccountsCount,
        'validAccountsList': _validAccountsList.map((a) => a.toJson()).toList(),
        'bannedAccountsList': _bannedAccountsList
            .map((a) => a.toJson())
            .toList(),
        'lockedAccountsList': _lockedAccountsList
            .map((a) => a.toJson())
            .toList(),
        'errorAccountsList': _errorAccountsList.map((a) => a.toJson()).toList(),
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
    _apiService?.clearCache();
    _log('Caché limpiado');
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getCacheStats() {
    return _apiService?.getCacheStats() ?? {'size': 0, 'maxSize': 0};
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
    super.dispose();
  }
}
