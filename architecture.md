# 🏗️ Kiến trúc Dự án Chiabill (Flutter)

Dự án Chiabill được xây dựng dựa trên framework **Flutter** dành cho ứng dụng di động (Android/iOS) và sử dụng kiến trúc phân tầng kết hợp với **GetX** để quản lý trạng thái, định tuyến và Dependency Injection.

## 1. Công nghệ & Thư viện sử dụng
- **Framework:** Flutter (Dart)
- **State Management & Routing:** [GetX](https://pub.dev/packages/get)
- **Networking:** [Dio](https://pub.dev/packages/dio) (Giao tiếp REST API với Backend Spring Boot)
- **Hình ảnh:** `cached_network_image`, `image_picker`
- **QR Code:** `mobile_scanner` (Quét mã), VietQR API (Tạo mã thanh toán)
- **Push Notification:** Firebase Cloud Messaging (FCM)
- **Auth:** Google Sign-In, Anonymous Login
- **UI/UX:** Tùy biến sâu, không lạm dụng thư viện UI có sẵn để giữ performance tốt và dễ dàng cá nhân hóa theme (AppColors).

## 2. Cấu trúc thư mục (Directory Structure)
Dự án áp dụng mô hình phân tách trách nhiệm (Separation of Concerns) rõ ràng:

```text
lib/
├── controllers/       # (ViewModel) Quản lý trạng thái và logic giao diện bằng GetX
├── data/
│   ├── models/        # DTOs, Requests, Responses (Ánh xạ 1:1 với Backend)
│   └── repositories/  # (Model) Gọi API thông qua ApiService, xử lý dữ liệu thô
├── network/           # Cấu hình Dio, Interceptors, Xử lý Token/Refresh Token
├── routes/            # Khai báo các Route và Bindings (GetPage)
├── screens/           # (View) Các màn hình giao diện (UI)
│   ├── auth/          # Đăng nhập, Chào mừng
│   ├── home/          # Danh sách chuyến đi
│   ├── profile/       # Cài đặt cá nhân, Bank QR
│   ├── tourism/       # Khám phá, Bản đồ du lịch
│   └── trip/          # Chi tiết chuyến đi, Thêm chi phí, Quyết toán, ...
├── theme/             # Định nghĩa màu sắc (AppColors), Typography, Styles
└── utils/             # Các hàm tiện ích (CurrencyFormat, Toast, Loading...)
```

## 3. Quy trình dòng chảy dữ liệu (Data Flow)
Mô hình hoạt động theo nguyên tắc **View -> Controller -> Repository -> API**:
1. **View (Screens):** Lắng nghe sự thay đổi của các biến `Rx` (Observable) bằng `Obx()` và rebuild UI. Gửi các Action (onTap, onRefresh) tới Controller.
2. **Controller:** Xử lý logic nghiệp vụ, giữ các trạng thái giao diện, kiểm tra validate, hiển thị Loading/Toast, và gọi Repository.
3. **Repository:** Đóng gói DTO, gửi HTTP Request qua lớp `ApiService` (Dio).
4. **ApiService:** Đính kèm Bearer Token, bắt lỗi chung (Timeout, 401 Unauthorized), trả về đối tượng `ApiResponse` thống nhất.

## 4. Nghiệp vụ riêng các tầng
- **Tầng View (Screens):** Tuyệt đối KHÔNG chứa logic tính toán phức tạp, KHÔNG gọi API trực tiếp. Chỉ tập trung vào vẽ UI và bắt sự kiện người dùng.
- **Tầng Controller:** Là "bộ não" của màn hình. Mỗi màn hình thường đi kèm một Controller (được tiêm qua Get.put hoặc Binding). Khi View bị hủy, Controller sẽ được xóa khỏi bộ nhớ để giải phóng RAM.
- **Tầng Repository:** Là "cầu nối" dữ liệu. Nếu tương lai thay đổi Backend (từ REST sang GraphQL, Firebase), chỉ cần sửa ở tầng này mà không ảnh hưởng đến Controller hay View.
