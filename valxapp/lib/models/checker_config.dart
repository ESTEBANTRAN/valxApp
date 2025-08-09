import '../utils/constants.dart';

class CheckerConfig {
  final int maxConcurrentRequests;
  final int requestTimeout;
  final int retryAttempts;
  final int retryDelay;
  final int rateLimitPerSecond;
  final List<String> regions;
  final bool enableCache;
  final int cacheDuration;
  final int maxCacheSize;
  final bool enableRandomDelays;
  final int minDelayBetweenRequests;
  final int maxDelayBetweenRequests;

  const CheckerConfig({
    this.maxConcurrentRequests = AppConstants.defaultMaxConcurrentRequests,
    this.requestTimeout = AppConstants.defaultRequestTimeout,
    this.retryAttempts = AppConstants.defaultRetryAttempts,
    this.retryDelay = AppConstants.defaultRetryDelay,
    this.rateLimitPerSecond = AppConstants.defaultRateLimitPerSecond,
    this.regions = AppConstants.availableRegions,
    this.enableCache = true,
    this.cacheDuration = AppConstants.cacheDurationHours,
    this.maxCacheSize = AppConstants.maxCacheSize,
    this.enableRandomDelays = AppConstants.enableRandomDelays,
    this.minDelayBetweenRequests = 3000, // 3 segundos mínimo
    this.maxDelayBetweenRequests = 8000, // 8 segundos máximo
  });

  CheckerConfig copyWith({
    int? maxConcurrentRequests,
    int? requestTimeout,
    int? retryAttempts,
    int? retryDelay,
    int? rateLimitPerSecond,
    List<String>? regions,
    bool? enableCache,
    int? cacheDuration,
    int? maxCacheSize,
    bool? enableRandomDelays,
    int? minDelayBetweenRequests,
    int? maxDelayBetweenRequests,
  }) {
    return CheckerConfig(
      maxConcurrentRequests: maxConcurrentRequests ?? this.maxConcurrentRequests,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      rateLimitPerSecond: rateLimitPerSecond ?? this.rateLimitPerSecond,
      regions: regions ?? this.regions,
      enableCache: enableCache ?? this.enableCache,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      enableRandomDelays: enableRandomDelays ?? this.enableRandomDelays,
      minDelayBetweenRequests: minDelayBetweenRequests ?? this.minDelayBetweenRequests,
      maxDelayBetweenRequests: maxDelayBetweenRequests ?? this.maxDelayBetweenRequests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxConcurrentRequests': maxConcurrentRequests,
      'requestTimeout': requestTimeout,
      'retryAttempts': retryAttempts,
      'retryDelay': retryDelay,
      'rateLimitPerSecond': rateLimitPerSecond,
      'regions': regions,
      'enableCache': enableCache,
      'cacheDuration': cacheDuration,
      'maxCacheSize': maxCacheSize,
      'enableRandomDelays': enableRandomDelays,
      'minDelayBetweenRequests': minDelayBetweenRequests,
      'maxDelayBetweenRequests': maxDelayBetweenRequests,
    };
  }

  factory CheckerConfig.fromJson(Map<String, dynamic> json) {
    return CheckerConfig(
      maxConcurrentRequests: json['maxConcurrentRequests'] ?? AppConstants.defaultMaxConcurrentRequests,
      requestTimeout: json['requestTimeout'] ?? AppConstants.defaultRequestTimeout,
      retryAttempts: json['retryAttempts'] ?? AppConstants.defaultRetryAttempts,
      retryDelay: json['retryDelay'] ?? AppConstants.defaultRetryDelay,
      rateLimitPerSecond: json['rateLimitPerSecond'] ?? AppConstants.defaultRateLimitPerSecond,
      regions: List<String>.from(json['regions'] ?? AppConstants.availableRegions),
      enableCache: json['enableCache'] ?? true,
      cacheDuration: json['cacheDuration'] ?? AppConstants.cacheDurationHours,
      maxCacheSize: json['maxCacheSize'] ?? AppConstants.maxCacheSize,
      enableRandomDelays: json['enableRandomDelays'] ?? AppConstants.enableRandomDelays,
      minDelayBetweenRequests: json['minDelayBetweenRequests'] ?? 3000,
      maxDelayBetweenRequests: json['maxDelayBetweenRequests'] ?? 8000,
    );
  }

  @override
  String toString() {
    return 'CheckerConfig(maxConcurrentRequests: $maxConcurrentRequests, requestTimeout: $requestTimeout, rateLimitPerSecond: $rateLimitPerSecond)';
  }
}
