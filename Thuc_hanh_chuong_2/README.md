# Bài thực hành chương 2 – Tiến trình và trao đổi thông tin

Bộ mã theo ba phần của đề `btth_ch2_tientrinh_tdtt_vie_full.pdf`, dành cho Ubuntu. Đây là code để bạn chạy demo và lấy kết quả thật, chưa phải báo cáo thực nghiệm đã hoàn thành.

| Thư mục | Phần thực hành | Câu hỏi |
|---|---|---|
| `01_chatroom` | Node.js + Express + EJS + Socket.IO | 1–5 |
| `02_rpc_rabbitmq` | Java client/server Fibonacci qua RabbitMQ | 6–8 |
| `03_video_netem` | VLC, script NetEm và video mẫu tạo sẵn | 9–17 |

**Bắt đầu bằng `docs/HUONG_DAN_UBUNTU.md`**, đi lần lượt từng phần. Kiểm tra công cụ trước:

```bash
bash check_environment.sh
```

- `docs/CAU_HOI_VA_ANH.md`: đối chiếu từng câu hỏi, đề xuất ảnh cần chụp.
- `docs/KIEM_THU.md`: những gì đã kiểm tra và giới hạn kiểm tra ở môi trường chuẩn bị.
- `docs/THAM_KHAO.md`: nguồn tài liệu kỹ thuật.
- `03_video_netem/results_template.csv`: bảng trống để ghi kết quả đo/quan sát.

Không cần Minikube hay Kubernetes cho chương này. Có thể dùng Docker sẵn trên máy để chạy RabbitMQ. Riêng video có hai lựa chọn: hai máy Ubuntu/VM theo đề, hoặc hai network namespace trên một Ubuntu để thử bằng một laptop. Namespace chỉ mô phỏng hai đầu mạng; nếu giảng viên yêu cầu đúng hai máy/VM, dùng phương án hai máy.

Các thư viện npm/Java tải ở lần cài hoặc build đầu tiên; ZIP không kèm node_modules/JDK/RabbitMQ. Các phiên bản npm đã có package-lock. Java dùng AMQP client 5.25.0 và SLF4J 2.0.17. Media gồm hai video mẫu 30 giây có thể phát lặp, do script ffmpeg tạo.

Khác biệt có chủ đích với bản mẫu:

1. Socket.IO client được phục vụ từ chính server để tương thích phiên bản, không phụ thuộc CDN 2.0.4.
2. Không dùng jQuery; giữ nguyên các event `change_username`, `new_message`, `typing` bằng JavaScript trình duyệt.
3. RPC tạo một callback queue cho mỗi client để dùng lại, thay vì tạo một queue ở mỗi lần call như code trong PDF; vẫn có correlationId riêng cho từng request.
4. Không purge hàng đợi khi server khởi động. Có timeout và trả lỗi rõ cho đối số Fibonacci sai.
5. VLC có chế độ **HTTP/OGG theo lệnh của đề** và **UDP/MPEG-TS bổ sung** vì phần mô tả và lệnh trong PDF không thống nhất giao thức.

Chạy local phục vụ học tập. Tin nhắn chỉ truyền tới các client đang kết nối, không có cơ sở dữ liệu/lịch sử. Queue RPC không durable và request không persistent, nên demo này không được coi là bảo đảm dữ liệu khi broker khởi động lại.
