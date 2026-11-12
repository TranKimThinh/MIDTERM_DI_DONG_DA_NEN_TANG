# Quản Lý Sản Phẩm (Admin CRUD) — Flutter & Firebase Cloud Firestore

Đề tài giữa kỳ môn **Lập trình Di động Đa nền tảng**: Ứng dụng quản lý danh mục sản phẩm dành cho quản trị viên (Admin), hỗ trợ đầy đủ các thao tác **Thêm – Xem – Sửa – Xóa (CRUD)**, đồng bộ dữ liệu theo thời gian thực (**real-time**) với **Firebase Cloud Firestore** và chạy đa nền tảng trên **Android** & **Web**.

---

## Tính năng chính

- **Đăng nhập phân hệ Admin (`LoginScreen`)**:
  - Xác thực tài khoản quản trị viên cục bộ, hiển thị trạng thái kết nối Firestore hay Demo tạm.
  - Hỗ trợ nút **Điền nhanh** thông tin tài khoản Admin mặc định để kiểm thử thuận tiện.
- **Dashboard thống kê & Giao diện thích ứng (`AdminDashboardScreen`)**:
  - Hiển thị 4 thẻ tổng quan: **Tổng sản phẩm**, **Tổng số lượng**, **Giá trị tồn kho** và số sản phẩm **Sắp hết / Hết**.
  - Tự động thích ứng theo chiều rộng màn hình (`>= 860px`): hiển thị dạng bảng **`DataTable`** trên Web/Desktop và danh sách thẻ gọn nhẹ kèm nút **`FloatingActionButton`** trên Mobile.
- **Quản lý sản phẩm CRUD theo thời gian thực**:
  - **Thêm / Cập nhật (`ProductFormDialog`)**: Kiểm tra hợp lệ dữ liệu nhập, ngăn trùng tên sản phẩm không phân biệt hoa/thường.
  - **Xem chi tiết (`ProductDetailDialog`)**: Hiển thị hình ảnh, giá bán (định dạng VNĐ), số lượng, tổng giá trị tồn kho, nguồn ảnh và trạng thái kho.
  - **Xóa sản phẩm**: Hộp thoại xác nhận trước khi xóa khỏi cơ sở dữ liệu.
  - **Cập nhật nhanh tồn kho**: Tăng/giảm trực tiếp số lượng (`adjustQuantity`) và đổi nhanh trạng thái kho (`Còn hàng`, `Sắp hết`, `Hết hàng`).
- **Xử lý hình ảnh linh hoạt (`ImageHelper`)**:
  - Chọn ảnh từ máy tính / thư viện ảnh, hoặc **chụp ảnh trực tiếp từ camera** (trên thiết bị di động).
  - Tự động thu gọn kích thước ảnh (`420x420`, chất lượng `55%`, giới hạn `<= 650 KB`) sang chuỗi **Base64 Data URI**, hoặc cho phép dán **URL hình ảnh** (`http://` / `https://`).
- **Tìm kiếm, Lọc & Sắp xếp**:
  - Tìm kiếm tức thì theo tên sản phẩm.
  - Lọc theo tình trạng kho: `Tất cả`, `Còn hàng (> 0)`, `Sắp hết (1–5)`, `Hết hàng (0)`.
  - Sắp xếp theo: `Mặc định`, `Tên A → Z`, `Tên Z → A`, `Giá thấp → cao`, `Giá cao → thấp`, `Số lượng nhiều nhất`.

---

## Cấu trúc dữ liệu Firestore & Mã nguồn

### Collection `products` trên Cloud Firestore
Mỗi document trong collection `products` lưu trữ đúng **4 trường** (`ProductModel.toFirestore()`):

| Tên trường | Kiểu dữ liệu | Mô tả |
| --- | --- | --- |
| `name` | `String` | Tên sản phẩm |
| `price` | `double` (`num`) | Giá bán (VNĐ) |
| `soluong` | `int` | Số lượng tồn kho |
| `image` | `String` | Link URL (`http`/`https`) hoặc chuỗi ảnh `data:image/...;base64,...` |

### Cấu trúc thư mục `lib/`
```text
lib/
├── main.dart                          # Khởi tạo Firebase/Repository và Provider
├── firebase_options.dart              # Cấu hình Firebase cho các nền tảng (Web, Android, iOS, ...)
├── models/
│   └── product_model.dart             # ProductModel & enum trạng thái kho ProductStockStatus
├── providers/
│   └── admin_provider.dart            # Quản lý state, đăng nhập, lọc, sắp xếp và CRUD
├── screens/
│   ├── login_screen.dart              # Màn hình đăng nhập Admin
│   └── admin_dashboard_screen.dart    # Màn hình chính Dashboard & danh sách sản phẩm
├── services/
│   └── product_repository.dart        # FirestoreProductRepository & LocalDemoProductRepository
├── utils/
│   ├── format_helper.dart             # Định dạng tiền tệ VNĐ và số lượng
│   └── image_helper.dart              # Chọn/chụp ảnh và mã hóa/giải mã Base64 & URL
└── widgets/
    ├── product_detail_dialog.dart     # Hộp thoại xem chi tiết sản phẩm
    ├── product_form_dialog.dart       # Form Thêm / Sửa sản phẩm (Dialog hoặc Fullscreen trên Mobile)
    └── product_image.dart             # Widget hiển thị ảnh URL / Base64 / ảnh mặc định
```

---

## Công nghệ sử dụng

- **Flutter** & **Dart SDK** (`^3.13.3`) — Giao diện Material 3
- **Provider** (`provider: ^6.1.5+1`) — Quản lý trạng thái (`ChangeNotifier`)
- **Firebase Core** (`firebase_core: ^5.1.0`) & **Cloud Firestore** (`cloud_firestore: ^7.1.0`) — Cơ sở dữ liệu NoSQL thời gian thực
- **Image Picker** (`image_picker: ^1.2.4`) — Chọn ảnh từ thiết bị / chụp ảnh từ camera

---

## Cách tải và cài đặt

### 1. Yêu cầu môi trường
- Đã cài đặt **Git** và **Flutter SDK** (Dart `^3.13.3`).
- Trình duyệt **Google Chrome** (nếu chạy bản Web) hoặc **Android SDK / thiết bị Android bật USB Debugging** (nếu chạy trên Android).

### 2. Tải mã nguồn (Clone repository)
```bash
git clone https://github.com/TranKimThinh/MIDTERM_DI_DONG_DA_NEN_TANG.git
cd MIDTERM_DI_DONG_DA_NEN_TANG
```

### 3. Cài đặt các gói thư viện
```bash
flutter pub get
```

### 4. Chạy ứng dụng

- **Chạy trên Web (Google Chrome):**
  ```bash
  flutter run -d chrome
  ```

- **Chạy trên điện thoại Android hoặc Emulator:**
  1. Kiểm tra ID thiết bị đang kết nối:
     ```bash
     flutter devices
     ```
  2. Chạy ứng dụng lên thiết bị:
     ```bash
     flutter run -d <DEVICE_ID>
     ```



