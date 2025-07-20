# Cập nhật Màn hình Ứng dụng - FocusLock

## 🎯 Mục tiêu

Đơn giản hóa giao diện màn hình Ứng dụng, chỉ hiển thị 4 danh mục lọc chính và lấy các ứng dụng thực tế có trong máy.

## ✅ Thay đổi đã thực hiện

### 1. **Đơn giản hóa danh mục lọc**

**File:** `lib/screens/apps_screen.dart`

**Trước:**
```dart
// 12 danh mục phức tạp
_buildCategoryButton('all', 'Tất cả', Icons.apps),
_buildCategoryButton('social', 'Mạng xã hội', Icons.people),
_buildCategoryButton('entertainment', 'Giải trí', Icons.movie),
_buildCategoryButton('gaming', 'Game', Icons.games),
_buildCategoryButton('communication', 'Liên lạc', Icons.message),
_buildCategoryButton('productivity', 'Làm việc', Icons.work),
_buildCategoryButton('shopping', 'Mua sắm', Icons.shopping_cart),
_buildCategoryButton('news', 'Tin tức', Icons.article),
_buildCategoryButton('education', 'Học tập', Icons.school),
_buildCategoryButton('finance', 'Tài chính', Icons.account_balance),
_buildCategoryButton('health', 'Sức khỏe', Icons.favorite),
_buildCategoryButton('travel', 'Du lịch', Icons.flight),
_buildCategoryButton('utilities', 'Tiện ích', Icons.build),
```

**Sau:**
```dart
// 4 danh mục chính, đơn giản
Expanded(child: _buildCategoryButton('all', 'Tất cả', Icons.apps)),
Expanded(child: _buildCategoryButton('social', 'Mạng xã hội', Icons.people)),
Expanded(child: _buildCategoryButton('entertainment', 'Giải trí', Icons.movie)),
Expanded(child: _buildCategoryButton('gaming', 'Game', Icons.games)),
```

### 2. **Cải thiện giao diện**

- **Loại bỏ ScrollView**: Thay vì scroll ngang, sử dụng `Expanded` để chia đều không gian
- **Responsive design**: 4 button chiếm đều không gian màn hình
- **Giao diện sạch sẽ**: Dễ nhìn và dễ sử dụng hơn

### 3. **Lấy ứng dụng thực tế từ máy**

**Logic hiện tại:**
```dart
// Lấy danh sách app thực tế đã cài trên máy
_allApps = await _appBlockingService.getInstalledApps();
```

**Android Implementation:**
```kotlin
private fun getInstalledApps(): List<Map<String, Any>> {
  val apps = mutableListOf<Map<String, Any>>()
  val popularSystemApps = setOf(
    "com.google.android.youtube",
    "com.facebook.katana",
    "com.instagram.android",
    "com.whatsapp",
    // ... các app phổ biến khác
  )
  
  val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
  for (appInfo in installedApps) {
    // Lọc: loại trừ FocusLock, chỉ lấy user app hoặc system app phổ biến
    if ((appInfo.packageName != context.packageName) &&
        ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
         popularSystemApps.contains(appInfo.packageName))) {
      
      val appName = packageManager.getApplicationLabel(appInfo).toString()
      apps.add(mapOf(
        "packageName" to appInfo.packageName,
        "appName" to appName,
        "isBlocked" to blockedApps.contains(appInfo.packageName)
      ))
    }
  }
  return apps
}
```

### 4. **Phân loại thông minh**

Sử dụng `AppUsageService.getAppsByCategory()` để phân loại các ứng dụng thực tế:

- **Tất cả**: Hiển thị tất cả ứng dụng
- **Mạng xã hội**: Facebook, Instagram, WhatsApp, Telegram, Discord, Reddit, etc.
- **Giải trí**: YouTube, Spotify, Netflix, Amazon Prime, etc.
- **Game**: Call of Duty, Fortnite, Minecraft, Clash of Clans, etc.

## 🎨 Giao diện mới

### Layout:
```
┌─────────────────────────────────────┐
│           Ứng dụng bị chặn          │
├─────────────────────────────────────┤
│ [🔍 Tìm kiếm ứng dụng...]           │
├─────────────────────────────────────┤
│ [📱] [👥] [🎬] [🎮]                │
│ Tất cả  Mạng    Giải    Game       │
│         xã hội   trí              │
├─────────────────────────────────────┤
│ ℹ️ Các ứng dụng được chọn sẽ bị     │
│    chặn trong thời gian tập trung   │
├─────────────────────────────────────┤
│ [App 1] [Switch]                    │
│ [App 2] [Switch]                    │
│ [App 3] [Switch]                    │
│ ...                                 │
└─────────────────────────────────────┘
```

### Tính năng:
- **Tìm kiếm**: Tìm kiếm ứng dụng theo tên
- **Lọc theo danh mục**: 4 danh mục chính
- **Toggle chặn**: Bật/tắt chặn từng ứng dụng
- **Real-time update**: Cập nhật ngay lập tức khi thay đổi

## 🔧 Cách hoạt động

### 1. **Khởi tạo**
```dart
Future<void> _loadApps() async {
  // Lấy danh sách app thực tế từ máy
  _allApps = await _appBlockingService.getInstalledApps();
  _filteredApps = List.from(_allApps);
}
```

### 2. **Lọc theo danh mục**
```dart
Future<void> _filterAppsByCategory(String category) async {
  if (category == 'all') {
    _filteredApps = List.from(_allApps);
  } else {
    // Sử dụng AppUsageService để phân loại
    final appUsageService = AppUsageService();
    _filteredApps = await appUsageService.getAppsByCategory(category, appsList: _allApps);
  }
}
```

### 3. **Cập nhật trạng thái**
```dart
void _toggleAppBlock(AppInfo app) {
  // Cập nhật UI
  final index = _allApps.indexWhere((a) => a.packageName == app.packageName);
  if (index != -1) {
    _allApps[index] = app.copyWith(isBlocked: !app.isBlocked);
  }
  
  // Cập nhật FocusService
  final focusService = Provider.of<FocusService>(context, listen: false);
  focusService.updateBlockedApps(_allApps);
}
```

## 📱 Trải nghiệm người dùng

### Trước khi cập nhật:
- ❌ 12 danh mục phức tạp, khó tìm
- ❌ Scroll ngang không tiện
- ❌ Giao diện rối mắt

### Sau khi cập nhật:
- ✅ 4 danh mục chính, dễ hiểu
- ✅ Layout responsive, đẹp mắt
- ✅ Lấy ứng dụng thực tế từ máy
- ✅ Phân loại thông minh
- ✅ Giao diện sạch sẽ, dễ sử dụng

## 🚀 Lợi ích

1. **Đơn giản hóa**: Chỉ 4 danh mục chính, dễ hiểu
2. **Thực tế**: Hiển thị ứng dụng thực tế có trong máy
3. **Thông minh**: Phân loại tự động dựa trên package name
4. **Responsive**: Giao diện đẹp trên mọi kích thước màn hình
5. **Hiệu quả**: Tìm kiếm và lọc nhanh chóng

## 🔮 Tương lai

Có thể mở rộng thêm:
- **Tùy chỉnh danh mục**: Cho phép người dùng tạo danh mục riêng
- **Thống kê sử dụng**: Hiển thị thời gian sử dụng mỗi ứng dụng
- **Gợi ý thông minh**: Gợi ý ứng dụng nên chặn dựa trên thói quen
- **Import/Export**: Xuất nhập danh sách ứng dụng bị chặn 