# Sửa lỗi Logic Chặn Ứng dụng - FocusLock

## 🐛 Vấn đề ban đầu

Khi cài đặt và sử dụng FocusLock lần đầu, sau khi cấp tất cả các quyền và vào chế độ tập trung, ứng dụng tự động hiển thị overlay chặn các ứng dụng mà không cần người dùng chọn trước.

## 🔍 Nguyên nhân

Vấn đề nằm ở logic trong `FocusService.init()` (dòng 60-70):

```dart
// If no blocked apps are set, add some default social media apps
if (_blockedApps.isEmpty) {
  _blockedApps = [
    AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook', isBlocked: true),
    AppInfo(packageName: 'com.instagram.android', appName: 'Instagram', isBlocked: true),
    // ... các app khác với isBlocked: true
  ];
}
```

Khi ứng dụng khởi động lần đầu và không có danh sách ứng dụng bị chặn được lưu, nó sẽ tự động thêm các ứng dụng mặc định với `isBlocked: true`, khiến cho khi bắt đầu phiên tập trung, tất cả các ứng dụng mặc định sẽ bị chặn ngay lập tức.

## ✅ Giải pháp đã thực hiện

### 1. **Sửa logic khởi tạo ứng dụng mặc định**

**File:** `lib/services/focus_service.dart`

```dart
// Thay đổi từ isBlocked: true thành isBlocked: false
if (_blockedApps.isEmpty) {
  _blockedApps = [
    AppInfo(packageName: 'com.facebook.katana', appName: 'Facebook', isBlocked: false),
    AppInfo(packageName: 'com.instagram.android', appName: 'Instagram', isBlocked: false),
    // ... tất cả app mặc định với isBlocked: false
  ];
}
```

### 2. **Sửa logic chặn ứng dụng trong startSession**

**File:** `lib/services/focus_service.dart`

```dart
// Chỉ chặn những app có isBlocked = true
final appsToBlock = _blockedApps.where((app) => app.isBlocked).toList();
await _appBlockingService.startBlocking(appsToBlock);
```

### 3. **Thêm getters để kiểm tra trạng thái**

**File:** `lib/services/focus_service.dart`

```dart
// Check if any apps are selected for blocking
bool get hasSelectedApps => _blockedApps.any((app) => app.isBlocked);

// Get selected apps for blocking
List<AppInfo> get selectedApps => _blockedApps.where((app) => app.isBlocked).toList();
```

### 4. **Thêm dialog hướng dẫn lần đầu sử dụng**

**File:** `lib/screens/home_screen.dart`

```dart
void _showFirstTimeDialog() {
  // Hiển thị hướng dẫn chi tiết cho người dùng lần đầu
  // Hướng dẫn cách chọn ứng dụng và bắt đầu phiên tập trung
}
```

### 5. **Thêm cảnh báo trong QuickStartWidget**

**File:** `lib/widgets/quick_start_widget.dart`

```dart
// Hiển thị cảnh báo khi chưa chọn ứng dụng nào
if (!widget.hasSelectedApps) {
  // Container cảnh báo màu cam
}
```

### 6. **Thêm dialog xác nhận khi bắt đầu phiên**

**File:** `lib/screens/home_screen.dart`

```dart
// Kiểm tra và hiển thị dialog xác nhận nếu chưa chọn app
if (!focusService.hasSelectedApps) {
  // Dialog xác nhận có muốn tiếp tục không
}
```

### 7. **Cải thiện updateBlockedApps**

**File:** `lib/services/focus_service.dart`

```dart
// Restart app blocking service khi có session đang chạy
if (_currentSession != null && _isActive) {
  final appsToBlock = apps.where((app) => app.isBlocked).toList();
  await _appBlockingService.stopBlocking();
  await _appBlockingService.startBlocking(appsToBlock);
}
```

## 🎯 Kết quả

### Trước khi sửa:
- ❌ Tự động chặn tất cả ứng dụng mặc định
- ❌ Không có hướng dẫn cho người dùng mới
- ❌ Không có cảnh báo khi chưa chọn ứng dụng

### Sau khi sửa:
- ✅ Chỉ chặn những ứng dụng được người dùng chọn
- ✅ Hiển thị hướng dẫn chi tiết cho người dùng lần đầu
- ✅ Cảnh báo rõ ràng khi chưa chọn ứng dụng
- ✅ Dialog xác nhận trước khi bắt đầu phiên
- ✅ Thông báo thành công với số lượng ứng dụng bị chặn

## 📱 Trải nghiệm người dùng mới

1. **Lần đầu mở app**: Hiển thị dialog chào mừng với hướng dẫn
2. **Tab Ứng dụng**: Hiển thị danh sách ứng dụng có thể chặn (mặc định không được chọn)
3. **Tab Trang chủ**: Hiển thị cảnh báo nếu chưa chọn ứng dụng
4. **Bắt đầu phiên**: Hiển thị dialog xác nhận nếu chưa chọn ứng dụng
5. **Thông báo**: Hiển thị số lượng ứng dụng bị chặn khi bắt đầu thành công

## 🔧 Cách test

1. Gỡ cài đặt ứng dụng
2. Cài đặt lại và mở lần đầu
3. Cấp tất cả quyền
4. Kiểm tra tab "Ứng dụng" - các app mặc định không được chọn
5. Vào tab "Trang chủ" - thấy cảnh báo chưa chọn ứng dụng
6. Bắt đầu phiên tập trung - thấy dialog xác nhận
7. Chọn một số ứng dụng trong tab "Ứng dụng"
8. Bắt đầu phiên tập trung - chỉ những app đã chọn bị chặn

## 📝 Lưu ý

- Các thay đổi này đảm bảo người dùng có quyền kiểm soát hoàn toàn việc chọn ứng dụng bị chặn
- Logic chặn ứng dụng vẫn hoạt động bình thường cho những ứng dụng được chọn
- Không ảnh hưởng đến các tính năng khác của ứng dụng 