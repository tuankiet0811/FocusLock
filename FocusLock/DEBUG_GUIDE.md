# Hướng dẫn Debug và Fix Lỗi FocusLock

## Vấn đề đã được sửa

### 1. Lỗi tính toán thời gian thực tế
- **Vấn đề**: Khi pause/resume session, thời gian thực tế bị tính sai
- **Nguyên nhân**: Logic tính toán `actualFocusMinutes` không chính xác khi có pause/resume
- **Giải pháp**: 
  - Sửa logic trong `calculateActualFocusTime()` để tính chính xác thời gian pause
  - Cập nhật `actualFocusMinutes` khi pause/resume
  - Đảm bảo thống kê sử dụng thời gian thực tế chính xác

### 2. Lỗi thống kê
- **Vấn đề**: Thống kê hiển thị sai do sử dụng dữ liệu không chính xác
- **Nguyên nhân**: Sử dụng `actualFocusMinutes` cũ hoặc null
- **Giải pháp**:
  - Sửa logic tính toán trong `StatisticsService`
  - Cập nhật UI để hiển thị thời gian thực tế chính xác
  - Thêm logic fallback cho các trường hợp null

## Cách sử dụng các tính năng Debug

### 1. Debug Session Info
- **Vị trí**: App bar trong Home screen (icon bug_report)
- **Chức năng**: In thông tin chi tiết session hiện tại vào console
- **Sử dụng**: Bấm icon bug_report để xem thông tin session

### 2. Debug Statistics
- **Vị trí**: App bar trong Session History screen (icon analytics)
- **Chức năng**: In thông tin chi tiết statistics vào console
- **Sử dụng**: Bấm icon analytics để xem thông tin statistics

### 3. Fix Sessions & Statistics
- **Vị trí**: App bar trong Session History screen (icon fix_normal)
- **Chức năng**: Tự động fix các session có dữ liệu không chính xác
- **Sử dụng**: Bấm icon fix_normal để fix và recalculate

### 4. Auto Cleanup Duplicates
- **Vị trí**: App bar trong Session History screen (icon auto_fix_high)
- **Chức năng**: Tự động dọn dẹp sessions trùng lặp
- **Sử dụng**: Bấm icon auto_fix_high để cleanup

## Cách kiểm tra lỗi đã được sửa

### 1. Test pause/resume
1. Bắt đầu một session mới
2. Pause session sau vài phút
3. Đợi một lúc rồi resume
4. Kiểm tra thời gian thực tế có chính xác không

### 2. Test statistics
1. Hoàn thành một vài sessions
2. Vào màn hình Statistics
3. Kiểm tra các số liệu có chính xác không
4. So sánh với Session History

### 3. Test fix functionality
1. Nếu có dữ liệu cũ không chính xác
2. Bấm "Fix Sessions & Statistics"
3. Kiểm tra lại thống kê

## Các thay đổi chính trong code

### 1. FocusSession.calculateActualFocusTime()
- Tính toán chính xác thời gian pause
- Sử dụng pauseHistory để tính tổng thời gian pause
- Đảm bảo không âm và không vượt quá duration

### 2. FocusService.pauseSession() & resumeSession()
- Cập nhật actualFocusMinutes khi pause/resume
- Tính toán chính xác thời gian pause
- Lưu thông tin vào pauseHistory

### 3. StatisticsService._calculateStatistics()
- Sử dụng actualFocusMinutes chính xác
- Fallback cho các trường hợp null
- Recalculate khi cần thiết

### 4. UI Components
- Hiển thị thời gian thực tế chính xác
- Tính toán performance percentage chính xác
- Cập nhật real-time khi có thay đổi

## Lưu ý quan trọng

1. **Backup dữ liệu**: Trước khi sử dụng các tính năng fix, nên backup dữ liệu
2. **Test kỹ**: Sau khi fix, test lại các tính năng pause/resume
3. **Monitor logs**: Sử dụng console để theo dõi quá trình debug
4. **Report issues**: Nếu vẫn có lỗi, báo cáo với thông tin debug

## Troubleshooting

### Nếu thời gian vẫn sai:
1. Bấm "Debug Session Info" để xem chi tiết
2. Bấm "Fix Sessions & Statistics" để fix
3. Test lại pause/resume

### Nếu thống kê vẫn sai:
1. Bấm "Debug Statistics" để xem chi tiết
2. Bấm "Fix Sessions & Statistics" để fix
3. Kiểm tra lại màn hình Statistics

### Nếu có lỗi khác:
1. Kiểm tra console logs
2. Sử dụng các tính năng debug
3. Báo cáo với thông tin chi tiết 