# Kiểm tra đã thực hiện khi chuẩn bị bộ mã

## Đã kiểm tra

- Chat: cài dependencies theo package.json, tạo package-lock; `npm test` chạy 5/5 nhóm kiểm tra đạt. Dùng hai client Socket.IO thật kết nối WebSocket tới server cục bộ để kiểm tra đổi tên, broadcast cho cả người gửi/người nhận, typing chỉ cho người khác, từ chối dữ liệu rỗng/quá dài; kiểm tra route EJS/client bundle và Hello world.
- Java: biên dịch toàn bộ 6 file Java (4 nguồn, 2 test) với Java17 runtime và compiler Eclipse ECJ3.40.0, dùng đúng AMQP client5.25.0 và SLF4J2.0.17. Tất cả biên dịch thành công. `FibonacciTest`: 15/15 trường hợp đạt, gồm giá trị0..10,31,92 và từ chối-1,93.
- Shell: kiểm tra cú pháp `bash -n` cho mọi script. Chạy `--dry-run` các profile NetEm để kiểm tra cách dựng đối số, không áp dụng lên mạng thật.
- Media: sinh hai video mẫu30giây và kiểm tra ffprobe: OGV chứa Theora/Vorbis, TS chứa MPEG-2 video/MP2 audio, đúng mục đích hai chế độ stream.
- LaTeX lý thuyết được biên dịch bằng XeLaTeX, đọc lại nội dung và kiểm tra bố cục bản PDF.

## Chưa kiểm thử đầu cuối trong môi trường chuẩn bị

- Không có RabbitMQ broker/Docker chạy tại đây. Chưa chạy `RpcIntegrationTest` qua một broker RabbitMQ thật, chưa xác nhận bảng queue khi nhiều client và delay2s. Bộ test đó đã được viết để bạn chạy trên Ubuntu theo hướng dẫn.
- Chưa kiểm thử giao diện chat bằng một browser tự động; đã kiểm tra chức năng qua client Socket.IO và HTTP. Thử tải browser kiểm thử không thành công nên không ghi nhận là browser-pass.
- Không có VLC GUI và môi trường mạng được cấu hình cho bài lab. Chưa chạy live VLC–NetEm, chưa tạo hai network namespace và chưa đo QoS. Các ảnh/kết quả video phải do bạn tự quan sát.

Do đó không nên mô tả ZIP này là đã có kết quả thực nghiệm cho cả ba phần. Code, video mẫu, test và hướng dẫn đã được chuẩn bị; kiểm thử tích hợp RabbitMQ/VLC còn cần chạy ở máy thực hành.
