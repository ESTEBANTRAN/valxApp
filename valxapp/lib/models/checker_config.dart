class CheckerConfig {
  final int maxConcurrentRequests;
  final int requestTimeout;
  final int retryAttempts;
  final int retryDelay;
  final int rateLimitPerSecond;
  final bool enableCache;
  final int cacheDuration;
  final int maxCacheSize;
  final List<String> regions;
  final int minLevel;
  final int maxLevel;
  final bool includeBanned;
  final bool includeLocked;
  final bool enableRandomDelays;
  final int minDelayBetweenRequests;
  final int maxDelayBetweenRequests;

  const CheckerConfig({
    this.maxConcurrentRequests = 5,
    this.requestTimeout = 20,
    this.retryAttempts = 3,
    this.retryDelay = 3,
    this.rateLimitPerSecond = 2,
    this.enableCache = true,
    this.cacheDuration = 24,
    this.maxCacheSize = 500,
    this.regions = const ['na', 'eu', 'ap', 'br', 'kr', 'latam'],
    this.minLevel = 1,
    this.maxLevel = 999,
    this.includeBanned = false,
    this.includeLocked = false,
    this.enableRandomDelays = true,
    this.minDelayBetweenRequests = 1000,
    this.maxDelayBetweenRequests = 3000,
  });

  factory CheckerConfig.fromJson(Map<String, dynamic> json) {
    return CheckerConfig(
      maxConcurrentRequests: json['maxConcurrentRequests'] ?? 5,
      requestTimeout: json['requestTimeout'] ?? 20,
      retryAttempts: json['retryAttempts'] ?? 3,
      retryDelay: json['retryDelay'] ?? 3,
      rateLimitPerSecond: json['rateLimitPerSecond'] ?? 2,
      enableCache: json['enableCache'] ?? true,
      cacheDuration: json['cacheDuration'] ?? 24,
      maxCacheSize: json['maxCacheSize'] ?? 500,
      regions: List<String>.from(
        json['regions'] ?? ['na', 'eu', 'ap', 'br', 'kr', 'latam'],
      ),
      minLevel: json['minLevel'] ?? 1,
      maxLevel: json['maxLevel'] ?? 999,
      includeBanned: json['includeBanned'] ?? false,
      includeLocked: json['includeLocked'] ?? false,
      enableRandomDelays: json['enableRandomDelays'] ?? true,
      minDelayBetweenRequests: json['minDelayBetweenRequests'] ?? 1000,
      maxDelayBetweenRequests: json['maxDelayBetweenRequests'] ?? 3000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxConcurrentRequests': maxConcurrentRequests,
      'requestTimeout': requestTimeout,
      'retryAttempts': retryAttempts,
      'retryDelay': retryDelay,
      'rateLimitPerSecond': rateLimitPerSecond,
      'enableCache': enableCache,
      'cacheDuration': cacheDuration,
      'maxCacheSize': maxCacheSize,
      'regions': regions,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'includeBanned': includeBanned,
      'includeLocked': includeLocked,
      'enableRandomDelays': enableRandomDelays,
      'minDelayBetweenRequests': minDelayBetweenRequests,
      'maxDelayBetweenRequests': maxDelayBetweenRequests,
    };
  }

  CheckerConfig copyWith({
    int? maxConcurrentRequests,
    int? requestTimeout,
    int? retryAttempts,
    int? retryDelay,
    int? rateLimitPerSecond,
    bool? enableCache,
    int? cacheDuration,
    int? maxCacheSize,
    List<String>? regions,
    int? minLevel,
    int? maxLevel,
    bool? includeBanned,
    bool? includeLocked,
    bool? enableRandomDelays,
    int? minDelayBetweenRequests,
    int? maxDelayBetweenRequests,
  }) {
    return CheckerConfig(
      maxConcurrentRequests:
          maxConcurrentRequests ?? this.maxConcurrentRequests,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      rateLimitPerSecond: rateLimitPerSecond ?? this.rateLimitPerSecond,
      enableCache: enableCache ?? this.enableCache,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      regions: regions ?? this.regions,
      minLevel: minLevel ?? this.minLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      includeBanned: includeBanned ?? this.includeBanned,
      includeLocked: includeLocked ?? this.includeLocked,
      enableRandomDelays: enableRandomDelays ?? this.enableRandomDelays,
      minDelayBetweenRequests:
          minDelayBetweenRequests ?? this.minDelayBetweenRequests,
      maxDelayBetweenRequests:
          maxDelayBetweenRequests ?? this.maxDelayBetweenRequests,
    );
  }

  @override
  String toString() {
    return 'CheckerConfig(maxConcurrentRequests: $maxConcurrentRequests, requestTimeout: $requestTimeout, rateLimitPerSecond: $rateLimitPerSecond)';
  }
}
