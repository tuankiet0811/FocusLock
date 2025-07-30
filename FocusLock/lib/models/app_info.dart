class AppInfo {
  final String packageName;
  final String appName;
  final bool isBlocked;
  final String? iconPath;
  final int usageTimeMinutes;
  final String category; // Thêm trường này

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.isBlocked,
    this.iconPath,
    this.usageTimeMinutes = 0,
    this.category = 'other', // Giá trị mặc định
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isBlocked': isBlocked,
      'iconPath': iconPath,
      'usageTimeMinutes': usageTimeMinutes,
      'category': category, // Thêm vào JSON
    };
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['packageName'],
      appName: json['appName'],
      isBlocked: json['isBlocked'],
      iconPath: json['iconPath'],
      usageTimeMinutes: json['usageTimeMinutes'] ?? 0,
      category: json['category'] ?? 'other', // Thêm vào factory
    );
  }

  AppInfo copyWith({
    String? packageName,
    String? appName,
    bool? isBlocked,
    String? iconPath,
    int? usageTimeMinutes,
    String? category, // Thêm vào copyWith
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isBlocked: isBlocked ?? this.isBlocked,
      iconPath: iconPath ?? this.iconPath,
      usageTimeMinutes: usageTimeMinutes ?? this.usageTimeMinutes,
      category: category ?? this.category, // Thêm vào copyWith
    );
  }
}