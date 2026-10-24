# Đối chiếu 17 câu hỏi và minh chứng

Đây là gợi ý để ghi báo cáo sau khi chạy, không thay cho kết quả thực nghiệm. Tên ảnh là đề xuất, không phải số lượng bắt buộc do đề quy định. Không cần viết lý thuyết quá dài; nêu đã làm gì, thấy gì và giải thích ngắn.

| Câu | Chỗ cần xem / nội dung trả lời | Minh chứng đề xuất |
|---|---|---|
| 1 | `npm init` tạo `package.json`, lưu thông tin, scripts và dependencies; project này đã có sẵn. | File package.json nếu cần |
| 2 | Chạy chế độ `hello`, trang trả `Hello world`. | chat_01_hello.png |
| 3 | Chế độ `server-only` chưa nhúng client Socket.IO nên reload trang không tạo sự kiện `connection` của Socket.IO. | Có thể chụp thêm trang + console |
| 4 | Chế độ `connect`: terminal có `New user connected`, browser báo đã kết nối. | chat_02_connected.png |
| 5 | Khi A gõ, B thấy thông báo A đang gõ; gửi tin xong thông báo tắt. | chat_03_messages.png và chat_04_typing.png |
| 6 | `RPCServer.java`, `new AMQP.BasicProperties.Builder().correlationId(delivery.getProperties().getCorrelationId()).build()` sao chép ID từ request vào reply. | Trích code, không bắt buộc ảnh riêng |
| 7 | Xem ba đoạn code bên dưới và đường đi request/reply. | rpc_01_fibonacci.png |
| 8 | Server delay2000ms, nhiều client, thống kê ready/unack; ghi số đúng thời điểm quan sát. | rpc_02_delay_queue.png |
| 9 | Ghi IP server/client thật và lệnh ping. Nếu dùng namespace ghi 10.202.0.1/10.202.0.2, interface eth0 trong namespace. | video_00_network.png |
| 10 | Ghi video có hình/tiếng không, tình trạng phát trước khi thêm NetEm. | video_01_baseline.png |
| 11 | So sánh RTT trước/sau delay100; một chiều bị thêm delay thì RTT tăng xấp xỉ100ms. | video_02_delay_ping.png |
| 12 | Mở lại client cache0, so sánh với cache1000; nhận xét thật, không khẳng định luôn giật. | video_03_lowcache.png |
| 13 | Thử jitter và jitter-corr, ghi cả cấu hình lẫn quan sát. PDF ghi “cũng như câu7” ở đây là dẫn chiếu nhầm; nội dung thực tế là đánh giá video. | video_04_jitter.png |
| 14 | Thử loss0.1% và một mức cao hơn, ghi sự khác biệt. | video_05_loss.png |
| 15 | Thử loss có tương quan0.3%/25%, có thể tăng mức nếu cần bằng lệnh riêng đã ghi rõ. | video_06_loss_corr.png |
| 16 | Thử duplicate1% và10%; trên HTTP/TCP có thể ít ảnh hưởng thấy được vì TCP loại dữ liệu trùng. | video_07_duplicate.png |
| 17 | Thử reorder25%/50% với delay10ms; giải thích khác biệt giữa HTTP/TCP và UDP nếu có chạy bổ sung. | video_08_reorder.png |

Đề còn hướng dẫn **corrupt0.1%** dù không có câu hỏi đánh số riêng: nên chạy và ghi một dòng kết quả, chụp `video_09_corrupt.png` nếu có khác biệt. Khi hết bài phải xóa NetEm; có thể chụp trạng thái sau reset.

## Đoạn code câu 7 trong bộ mã này

Trong constructor `RPCClient`:

```java
callbackQueue = opened.queueDeclare("", false, true, true, null).getQueue();
opened.basicConsume(callbackQueue, true, callback, cancelCallback);
```

Tên queue được broker tạo; exclusive/auto-delete phục vụ riêng kết nối client. Bản code đầy đủ dùng lambda thay tên `callback` trong đoạn minh họa này.

Trong `RPCClient.call`:

```java
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
    .correlationId(corrId)
    .replyTo(replyQueueName)
    .contentType("text/plain")
    .build();
channel.basicPublish("", RpcConfig.queue(), props,
    message.getBytes(StandardCharsets.UTF_8));
```

`RpcConfig.queue()` mặc định `rpc_queue`. Default exchange `""` định tuyến theo tên queue. Server consume queue đó, tính Fibonacci và gửi kết quả tới `replyTo`; client so ID để nhận đúng kết quả.

**Khác biệt với PDF:** trong PDF, `queueDeclare().getQueue()` nằm trong `call`, tức mỗi call tạo một callback queue mới. Bộ mã này chuyển nó vào constructor để mỗi client dùng lại một queue; correlationId vẫn mới mỗi lần. Nếu báo cáo mô tả code của PDF thì nêu đúng vị trí trong PDF; nếu mô tả code đang chạy thì nêu đúng cấu trúc này.

## Ghi nhận QoS hợp lý

- Ghi protocol và cache mỗi lần. HTTP/TCP có truyền lại, còn UDP không tự truyền lại.
- Ghi `tc -s qdisc` để thấy profile đã áp dụng và số liệu thống kê.
- Chỉ coi một hình bị vỡ/đứng là quan sát tại thời điểm đó; muốn khẳng định mức ảnh hưởng thì so nhiều lần với baseline cùng video/thời gian.
- Không điền trước “loss là giật” nếu thực tế vẫn mượt. Delay cố định, jitter và giảm cache có thể biểu hiện khác nhau.
- Corruption và reorder có thể bị che bởi xử lý giao thức/offload; báo cáo đúng điều quan sát, không tự tạo số liệu.
- CSV trong `03_video_netem` là mẫu trống, không phải kết quả có sẵn.
