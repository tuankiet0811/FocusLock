# Hướng dẫn Build và Publish FocusLock lên Google Play

## 📋 Chuẩn bị

### 1. Tài khoản Google Play Console
- Đăng ký tài khoản Google Play Console Developer (phí $25 một lần)
- Truy cập: https://play.google.com/console

### 2. Chuẩn bị tài liệu
- **Icon ứng dụng**: 512x512px PNG
- **Screenshot**: ít nhất 2 ảnh chụp màn hình (16:9 hoặc 9:16)
- **Mô tả ứng dụng**: Tiếng Việt và Tiếng Anh
- **Chính sách bảo mật**: URL hoặc file PDF

## 🔧 Cấu hình Build

### 1. Tạo Keystore cho Release

```bash
# Tạo keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Di chuyển keystore vào thư mục android
mv ~/upload-keystore.jks android/app/upload-keystore.jks
```

### 2. Cấu hình Signing

**Tạo file `android/key.properties`:**
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

**Cập nhật `android/app/build.gradle`:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3. Cập nhật Icon ứng dụng

**Thay thế các file icon trong:**
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**Kích thước icon:**
- hdpi: 72x72px
- mdpi: 48x48px
- xhdpi: 96x96px
- xxhdpi: 144x144px
- xxxhdpi: 192x192px

## 🏗️ Build ứng dụng

### 1. Build App Bundle (Khuyến nghị cho Google Play)

```bash
flutter build appbundle --release
```

File output: `build/app/outputs/bundle/release/app-release.aab`

### 2. Build APK (Để test)

```bash
flutter build apk --release
```

File output: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Test ứng dụng

```bash
# Cài đặt APK để test
flutter install --release
```

## 📱 Upload lên Google Play Console

### 1. Tạo ứng dụng mới

1. Đăng nhập Google Play Console
2. Chọn "Tạo ứng dụng"
3. Điền thông tin cơ bản:
   - **Tên ứng dụng**: FocusLock
   - **Ngôn ngữ mặc định**: Tiếng Việt
   - **Ứng dụng hoặc trò chơi**: Ứng dụng
   - **Miễn phí hoặc trả phí**: Miễn phí

### 2. Cấu hình Store Listing

**Thông tin ứng dụng:**
- **Tên ứng dụng**: FocusLock
- **Mô tả ngắn**: Ứng dụng chống nghiện điện thoại, giúp bạn tập trung vào công việc quan trọng
- **Mô tả đầy đủ**: 
```
FocusLock là ứng dụng giúp bạn tập trung vào công việc quan trọng bằng cách chặn các ứng dụng mạng xã hội và giải trí trong thời gian tập trung.

🌟 TÍNH NĂNG CHÍNH:
• Quản lý phiên tập trung từ 15 phút đến 2 giờ
• Chặn các ứng dụng mạng xã hội: Facebook, Instagram, TikTok, Twitter, Threads
• Thống kê thời gian tập trung hàng ngày và hàng tuần
• Thông báo thông minh và động viên
• Giao diện đẹp mắt và dễ sử dụng

🎯 CÁCH SỬ DỤNG:
1. Chọn thời gian tập trung
2. Đặt mục tiêu (tùy chọn)
3. Bắt đầu phiên tập trung
4. Các ứng dụng bị chặn sẽ không thể mở trong thời gian này
5. Theo dõi tiến độ và thành tích

📊 THEO DÕI TIẾN ĐỘ:
• Thống kê thời gian tập trung mỗi ngày
• Lịch sử các phiên tập trung
• Chuỗi thành tích liên tiếp
• Biểu đồ tiến độ trực quan

🔔 THÔNG BÁO THÔNG MINH:
• Thông báo khi bắt đầu/kết thúc phiên
• Tin nhắn động viên trong quá trình tập trung
• Cảnh báo khi cố gắng mở ứng dụng bị chặn

Hãy bắt đầu hành trình tập trung của bạn ngay hôm nay với FocusLock!
```

**Từ khóa**: focus, concentration, productivity, social media blocker, time management, study app

**Danh mục**: Productivity

### 3. Upload Assets

**Icon ứng dụng:**
- Upload file 512x512px PNG

**Screenshot:**
- Tối thiểu 2 ảnh chụp màn hình
- Kích thước: 16:9 hoặc 9:16
- Chất lượng cao, không có thanh trạng thái

**Video (tùy chọn):**
- Video demo 30 giây
- Hiển thị các tính năng chính

### 4. Cấu hình Content Rating

**Điền bảng câu hỏi:**
- **Bạo lực**: Không có
- **Tình dục**: Không có
- **Ngôn ngữ**: Không có
- **Kiểm soát chất**: Không có

### 5. Cấu hình App Release

**Upload App Bundle:**
1. Chọn "Production"
2. Upload file `app-release.aab`
3. Điền Release notes:
```
Phiên bản đầu tiên của FocusLock!

Tính năng:
• Quản lý phiên tập trung
• Chặn ứng dụng mạng xã hội
• Thống kê và theo dõi tiến độ
• Thông báo thông minh
• Giao diện đẹp mắt
```

### 6. Cấu hình Pricing & Distribution

**Pricing:**
- **Miễn phí**: Có
- **Quảng cáo**: Không

**Countries:**
- Chọn tất cả quốc gia hoặc chỉ Việt Nam

**Content guidelines:**
- Đồng ý với tất cả điều khoản

## 📋 Chính sách bảo mật

**Tạo file `privacy_policy.md`:**
```markdown
# Chính sách bảo mật FocusLock

## Thông tin thu thập
FocusLock chỉ lưu trữ dữ liệu cục bộ trên thiết bị của bạn:
- Thời gian tập trung
- Danh sách ứng dụng bị chặn
- Cài đặt cá nhân

## Quyền sử dụng
- PACKAGE_USAGE_STATS: Theo dõi việc sử dụng ứng dụng để chặn
- SYSTEM_ALERT_WINDOW: Hiển thị cảnh báo khi chặn ứng dụng
- FOREGROUND_SERVICE: Chạy service trong nền
- POST_NOTIFICATIONS: Gửi thông báo

## Bảo mật dữ liệu
- Không thu thập thông tin cá nhân
- Không chia sẻ dữ liệu với bên thứ ba
- Dữ liệu chỉ lưu trữ cục bộ

## Liên hệ
Email: support@focuslock.app
```

## 🚀 Publish

### 1. Review và Submit

1. Kiểm tra lại tất cả thông tin
2. Nhấn "Review release"
3. Nhấn "Start rollout to Production"

### 2. Thời gian xử lý

- **Review**: 1-7 ngày làm việc
- **Publish**: Ngay sau khi được chấp thuận

### 3. Theo dõi

- Kiểm tra email từ Google Play Console
- Theo dõi trạng thái trong Console
- Xem báo cáo sau khi publish

## 📈 Tối ưu hóa

### 1. ASO (App Store Optimization)

**Từ khóa tối ưu:**
- focus app
- concentration app
- productivity app
- social media blocker
- time management
- study app
- digital wellbeing

**Mô tả tối ưu:**
- Sử dụng từ khóa tự nhiên
- Liệt kê tính năng rõ ràng
- Thêm emoji để thu hút
- Cập nhật thường xuyên

### 2. Marketing

**Channels:**
- Social media (Facebook, Instagram)
- YouTube tutorials
- Blog posts
- Influencer marketing
- App review sites

**Content:**
- Video demo
- Screenshots đẹp
- User testimonials
- Tips and tricks

## 🔄 Cập nhật

### 1. Tăng version number

```yaml
# pubspec.yaml
version: 1.0.1+2
```

### 2. Build và upload

```bash
flutter build appbundle --release
```

### 3. Release notes

```
Cập nhật v1.0.1:
• Sửa lỗi crash khi tạm dừng phiên
• Cải thiện hiệu suất
• Thêm tính năng mới
```

## 📞 Hỗ trợ

**Chuẩn bị:**
- FAQ
- Hướng dẫn sử dụng
- Email support
- Social media channels

**Monitoring:**
- Crash reports
- User feedback
- Performance metrics
- Download statistics

---

**Lưu ý quan trọng:**
- Luôn test kỹ trước khi release
- Backup keystore file
- Theo dõi feedback người dùng
- Cập nhật thường xuyên
- Tuân thủ chính sách Google Play 