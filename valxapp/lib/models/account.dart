class Account {
  final String username;
  final String password;
  final String? status;
  final String? region;
  final int? level;
  final bool? hasSkins;
  final bool? isBanned;
  final bool? isLocked;
  final String? errorMessage;
  final DateTime? lastChecked;
  final Map<String, dynamic>? additionalData;

  const Account({
    required this.username,
    required this.password,
    this.status,
    this.region,
    this.level,
    this.hasSkins,
    this.isBanned,
    this.isLocked,
    this.errorMessage,
    this.lastChecked,
    this.additionalData,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      status: json['status'],
      region: json['region'],
      level: json['level'],
      hasSkins: json['hasSkins'],
      isBanned: json['isBanned'],
      isLocked: json['isLocked'],
      errorMessage: json['errorMessage'],
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'])
          : null,
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'status': status,
      'region': region,
      'level': level,
      'hasSkins': hasSkins,
      'isBanned': isBanned,
      'isLocked': isLocked,
      'errorMessage': errorMessage,
      'lastChecked': lastChecked?.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  Account copyWith({
    String? username,
    String? password,
    String? status,
    String? region,
    int? level,
    bool? hasSkins,
    bool? isBanned,
    bool? isLocked,
    String? errorMessage,
    DateTime? lastChecked,
    Map<String, dynamic>? additionalData,
  }) {
    return Account(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      region: region ?? this.region,
      level: level ?? this.level,
      hasSkins: hasSkins ?? this.hasSkins,
      isBanned: isBanned ?? this.isBanned,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: errorMessage ?? this.errorMessage,
      lastChecked: lastChecked ?? this.lastChecked,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'Account(username: $username, status: $status, region: $region, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.username == username;
  }

  @override
  int get hashCode => username.hashCode;
}
