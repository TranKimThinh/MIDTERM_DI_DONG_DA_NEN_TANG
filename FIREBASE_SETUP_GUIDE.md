# Hướng Dẫn Kết Nối Firebase Cho Dự Án Quản Lý Sản Phẩm

Hiện tại dự án đã hoàn thiện đầy đủ code giao diện và logic CRUD Sản phẩm với Firebase Cloud Firestore (collection `products` chỉ lưu đúng 4 trường `name`, `price`, `soluong`, `image`). Khi chưa gắn khóa dự án Firebase thật, ứng dụng tự chạy ở **Chế độ Demo tạm** để bạn kiểm tra trước giao diện.

* **Tài khoản đăng nhập phân hệ Admin:** `admin@gmail.com` / `123456` *(hoặc bấm nút **Điền nhanh** trên màn hình đăng nhập)*.

---

## Bước 1: Tạo Project & Bật Cloud Firestore
1. Truy cập [Firebase Console](https://console.firebase.google.com/) và bấm **Add project**.
2. Đặt tên project (ví dụ: `flutter-product-admin`) và hoàn tất tạo project.
3. Trong menu bên trái, vào **Build → Firestore Database** → bấm **Create database**.
4. Chọn vị trí server (ví dụ `asia-southeast1` - Singapore) → chọn **Start in test mode** → bấm **Enable**.

---

## Bước 2: Đăng nhập Firebase CLI & Cấu hình FlutterFire
Mở Terminal tại thư mục `d:\DiDongDaNenTang\MidtermCRUD` và chạy lần lượt các lệnh sau:

1. Đăng nhập tài khoản Google chứa Firebase Project:
   ```bash
   firebase login
   ```
2. Cài đặt FlutterFire CLI (nếu máy chưa có):
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. Kết nối dự án Flutter với Firebase Project (tick chọn cả **android** và **web** bằng phím Space):
   ```bash
   flutterfire configure
   ```
   *(Nếu máy chưa nhận lệnh `flutterfire`, chạy: `dart pub global run flutterfire_cli:flutterfire configure`)*.

   Lệnh này sẽ tự động ghi đè file `lib/firebase_options.dart` bằng thông số thật của bạn. Ngay khi file này được cập nhật, ứng dụng sẽ **tự động chuyển sang dùng Firebase Cloud Firestore thật**.

---

## Bước 3: Chạy kiểm tra trên Web và Di động

* **Chạy trên nền tảng Web (8.0đ + 1.5đ):**
  ```bash
  flutter run -d chrome
  ```
* **Chạy trên nền tảng Di động Android (0.5đ chọn & hiển thị ảnh):**
  ```bash
  flutter run
  ```

---

## Bước 4: Kiểm tra dữ liệu trên Firebase Console
1. Đăng nhập vào phân hệ Admin (`admin@gmail.com` / `123456`) và thực hiện Thêm / Sửa / Xóa sản phẩm.
2. Mở tab **Firestore Database** trên Firebase Console để chụp ảnh minh chứng collection `products` chỉ có **đúng 4 trường**: `name`, `price`, `soluong`, `image` (không có bất kỳ trường thừa nào).
