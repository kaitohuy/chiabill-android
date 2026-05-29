# 🌟 Kế Hoạch Phát Triển Tính Năng (Feature Plan)

Danh sách các tính năng dự định phát triển trong các phiên bản tiếp theo của Chiabill, nhằm tối ưu hóa trải nghiệm người dùng và mở rộng độ phủ của ứng dụng.

## 1. Quản lý "Quỹ chung" (Group Fund / Thu quỹ trước)
**Mô tả:** Thay vì mọi người tự trả các khoản nhỏ rồi cấn trừ sau, các nhóm bạn ở Việt Nam thường có văn hóa "mỗi người nộp trước một khoản làm quỹ", thủ quỹ sẽ cầm tiền đó đi tiêu chung.
**Tính năng cụ thể:**
- Cho phép khởi tạo "Quỹ chung" trong một chuyến đi.
- Cho phép thu tiền trước từ các thành viên và ghi nhận vào quỹ.
- Các khoản chi tiêu sau đó có thể chọn nguồn tiền từ "Quỹ chung" để trừ dần.
- Nếu quỹ sắp hết sẽ có thông báo (báo động) để nộp thêm.
- Cuối chuyến đi, tự động tính toán nếu quỹ thừa thì chia đều hoàn trả lại cho các thành viên.

## 4. Tùy biến Chia tiền nâng cao (Advanced Split)
**Mô tả:** Cung cấp cơ chế chia tiền phức tạp hơn thay vì chỉ chia đều.
**Tính năng cụ thể:**
- **Chia theo phần trăm (%):** Người A chịu 70%, người B chịu 30%.
- **Chia theo số tiền cụ thể:** Người A trả chính xác 50k, số còn lại chia đều cho những người khác.
- **Chia theo tỷ trọng (Shares):** Gia đình A có 3 người (3 phần), bạn B đi 1 mình (1 phần).

## 5. Chế độ Ngoại tuyến (Offline Mode)
**Mô tả:** Hỗ trợ nhập chi phí ngay cả khi đi du lịch vùng núi, nước ngoài không có mạng 4G.
**Tính năng cụ thể:**
- Cache toàn bộ dữ liệu chuyến đi bằng SQFlite hoặc Hive.
- Cho phép tạo khoản chi phí offline.
- Tự động đồng bộ hóa (Sync) lên Server Backend ngay khi thiết bị có kết nối mạng trở lại.
