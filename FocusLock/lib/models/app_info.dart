class AppInfo {
  final String packageName;
  final String appName;
  final bool isBlocked;
  final String? iconPath;
  final int usageTimeMinutes;

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.isBlocked,
    this.iconPath,
    this.usageTimeMinutes = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isBlocked': isBlocked,
      'iconPath': iconPath,
      'usageTimeMinutes': usageTimeMinutes,
    };
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['packageName'],
      appName: json['appName'],
      isBlocked: json['isBlocked'],
      iconPath: json['iconPath'],
      usageTimeMinutes: json['usageTimeMinutes'] ?? 0,
    );
  }

  AppInfo copyWith({
    String? packageName,
    String? appName,
    bool? isBlocked,
    String? iconPath,
    int? usageTimeMinutes,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
      iconPath: iconPath ?? this.iconPath,
      usageTimeMinutes: usageTimeMinutes ?? this.usageTimeMinutes,
    );
  }
} 