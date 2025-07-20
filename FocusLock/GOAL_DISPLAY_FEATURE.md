# Tính năng Hiển thị Mục tiêu - FocusLock

## 🎯 Mục tiêu

Thêm tính năng hiển thị mục tiêu mà người dùng đã nhập ở trên đầu giao diện sau khi bắt đầu phiên tập trung.

## ✅ Thay đổi đã thực hiện

### 1. **Cập nhật FocusTimerWidget**

**File:** `lib/widgets/focus_timer_widget.dart`

**Thêm tham số goal:**
```dart
class FocusTimerWidget extends StatefulWidget {
  // ... các tham số khác
  final String? goal;

  const FocusTimerWidget({
    // ... các tham số khác
    this.goal,
  });
}
```

**Thêm hiển thị mục tiêu:**
```dart
// Goal display (if exists)
if (widget.goal != null && widget.goal!.isNotEmpty) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.flag,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.goal!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16),
],
```

### 2. **Cập nhật HomeScreen**

**File:** `lib/screens/home_screen.dart`

**Truyền goal vào FocusTimerWidget:**
```dart
FocusTimerWidget(
  // ... các tham số khác
  goal: focusService.currentSession?.goal,
),
```

### 3. **Model FocusSession đã sẵn sàng**

**File:** `lib/models/focus_session.dart`

Model đã có sẵn trường `goal`:
```dart
class FocusSession {
  // ... các trường khác
  final String? goal;
  
  // Constructor, toJson, fromJson, copyWith đã được implement
}
```

## 🎨 Giao diện mới

### Layout khi có mục tiêu:
```
┌─────────────────────────────────────┐
│ 🏁 [Mục tiêu của bạn]               │
├─────────────────────────────────────┤
│           ⏰ Timer Circle            │
│           [25:30]                   │
│           Còn lại                   │
├─────────────────────────────────────┤
│ 💪 Tin nhắn động viên               │
├─────────────────────────────────────┤
│ [Dừng] [Tạm dừng/Tiếp tục]         │
└─────────────────────────────────────┘
```

### Layout khi không có mục tiêu:
```
┌─────────────────────────────────────┐
│           ⏰ Timer Circle            │
│           [25:30]                   │
│           Còn lại                   │
├─────────────────────────────────────┤
│ 💪 Tin nhắn động viên               │
├─────────────────────────────────────┤
│ [Dừng] [Tạm dừng/Tiếp tục]         │
└─────────────────────────────────────┘
```

## 🔧 Cách hoạt động

### 1. **Nhập mục tiêu**
- Người dùng nhập mục tiêu trong trường "Mục tiêu (tùy chọn)" trong QuickStartWidget
- Mục tiêu được lưu vào `FocusSession.goal`

### 2. **Hiển thị mục tiêu**
- Khi bắt đầu phiên tập trung, `FocusTimerWidget` kiểm tra `goal`
- Nếu có mục tiêu, hiển thị ở trên đầu với icon cờ 🏁
- Nếu không có mục tiêu, không hiển thị phần này

### 3. **Styling**
- **Background**: Màu trắng trong suốt (20% opacity)
- **Border**: Viền trắng mỏng (30% opacity)
- **Icon**: Cờ màu trắng
- **Text**: Màu trắng, font weight 500
- **Responsive**: Tối đa 2 dòng, overflow ellipsis

## 📱 Trải nghiệm người dùng

### Khi có mục tiêu:
1. **Nhập mục tiêu**: "Hoàn thành bài tập toán"
2. **Bắt đầu phiên**: Mục tiêu hiển thị ở trên đầu timer
3. **Nhắc nhở liên tục**: Luôn thấy mục tiêu trong quá trình tập trung
4. **Tăng động lực**: Nhắc nhở lý do tại sao đang tập trung

### Khi không có mục tiêu:
- Giao diện gọn gàng, chỉ hiển thị timer và controls
- Không có phần mục tiêu

## 🎯 Lợi ích

1. **Tăng động lực**: Người dùng luôn nhớ lý do tập trung
2. **Tập trung tốt hơn**: Mục tiêu cụ thể giúp tập trung hiệu quả hơn
3. **Giao diện đẹp**: Hiển thị mục tiêu một cách thẩm mỹ
4. **Tùy chọn**: Không bắt buộc, người dùng có thể bỏ qua
5. **Responsive**: Hoạt động tốt trên mọi kích thước màn hình

## 🔮 Tương lai

Có thể mở rộng thêm:
- **Mục tiêu mặc định**: Gợi ý mục tiêu dựa trên thời gian
- **Mục tiêu theo ngày**: Lưu mục tiêu cho từng ngày
- **Thống kê mục tiêu**: Theo dõi tỷ lệ hoàn thành mục tiêu
- **Chia sẻ mục tiêu**: Chia sẻ mục tiêu với bạn bè
- **Nhắc nhở mục tiêu**: Thông báo nhắc nhở mục tiêu

## 📝 Lưu ý kỹ thuật

- **Performance**: Sử dụng `const` widgets để tối ưu
- **Memory**: Goal được lưu trong session, không tốn thêm memory
- **Compatibility**: Tương thích với tất cả phiên bản hiện tại
- **Testing**: Cần test với mục tiêu dài và ngắn 