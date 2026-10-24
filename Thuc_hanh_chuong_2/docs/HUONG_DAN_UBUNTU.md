# Hướng dẫn demo từng bước trên Ubuntu

Mở terminal tại thư mục `Thuc_hanh_chuong_2` sau khi giải nén. Nên để project trong thư mục home, ví dụ `~/distributed-lab/Thuc_hanh_chuong_2`. Mỗi terminal mới phải `cd` về đúng phần đang chạy. Có thể gọi mọi script bằng `bash`, không cần chmod.

## 0. Kiểm tra môi trường

```bash
bash check_environment.sh
```

Cần Node.js >=20 và npm cho chat, JDK 17 trở lên cho Java. Bạn đã dùng nvm thì giữ Node từ nvm, không cần cài thêm Node bằng apt. Nếu chưa có Node, dùng hướng dẫn cài chính thức tại https://nodejs.org/en/download.

Cài các công cụ còn thiếu bằng apt, không cần cài lại thứ đã có:

```bash
sudo apt update
sudo apt install openjdk-17-jdk curl vlc ffmpeg iproute2 iputils-ping
node --version
npm --version
java -version
javac -version
docker info
```

Nếu `docker info` báo permission denied, kiểm tra nhóm Docker như đã làm ở chương 1. Không chạy chương trình VLC bằng sudo/root. Không chạy `npm install` bằng sudo trong project.

## 1. Chat room – câu 1–5

### 1.1 Cài thư viện

```bash
cd 01_chatroom
npm ci
npm test
```

`package.json` mô tả project, scripts và dependencies; `package-lock.json` cố định cây thư viện. Project đã được khởi tạo nên không cần chạy lại `npm init`. Nếu muốn minh họa riêng câu 1, có thể chạy `npm init -y` trong một thư mục trống khác để quan sát file mới.

### 1.2 Các bước trung gian đúng đề

```bash
npm run hello
```

Mở http://localhost:3000. Hiện **Hello world** (câu 2). Chụp `chat_01_hello.png`. Ctrl+C để dừng.

```bash
npm run server-only
```

Reload trang vài lần. Vẫn Hello world, **không có** dòng `New user connected` do trang chưa tải client Socket.IO (câu 3). Không nhầm socket HTTP tải trang với kết nối Socket.IO. Chụp nếu muốn minh họa; sau đó Ctrl+C.

```bash
npm run connect
```

Reload. Trang có trạng thái **Đã kết nối**, terminal xuất hiện `New user connected` (câu 4). Chụp trang và terminal, tên gợi ý `chat_02_connected.png`. Ctrl+C.

### 1.3 Chat hoàn chỉnh

```bash
npm start
```

- Mở 2 cửa sổ hoặc 2 tab cùng http://localhost:3000.
- Cửa sổ A đặt tên Ba, bấm Đổi tên; cửa sổ B đặt tên An.
- Gửi tin từ A; cả A và B phải nhìn thấy. Gửi ngược lại từ B.
- Chụp hai cửa sổ có hội thoại: `chat_03_messages.png`.
- Gõ liên tục tại A, chưa bấm Gửi. B nhìn thấy **Ba đang gõ...**; A không nhận thông báo typing của chính mình. Chụp `chat_04_typing.png` (câu 5).
- Dừng gõ một lúc thì thông báo tự mất.

Nếu cổng 3000 bận, dùng `PORT=3001 npm start` và mở đúng cổng mới. `npm run dev` dùng nodemon nếu bạn muốn sửa code. Khi dùng hai máy, browser máy B mở `http://IP_MAY_A:3000`; `io()` trong code tự dùng đúng máy đang phục vụ trang, không phải localhost của máy B. Chỉ mở firewall cho cổng cần dùng nếu firewall thực sự đang chặn.

## 2. RPC Java và RabbitMQ – câu 6–8

### 2.1 Khởi động broker (khuyến nghị dùng Docker đã có)

Mở terminal tại `02_rpc_rabbitmq`:

```bash
cd ../02_rpc_rabbitmq
bash broker.sh start
```

Lần đầu Docker tải image, cần Internet và thời gian chờ. Script chờ broker sẵn sàng. Giao diện quản lý: http://localhost:15672, tài khoản local `guest`, mật khẩu `guest`.

Nếu port 5672 đã có RabbitMQ cài trực tiếp đang chạy, có thể dùng broker đó và bỏ qua `broker.sh start`. Không chạy đồng thời hai broker chiếm cùng port. `RABBITMQ_HOST` mặc định localhost, port 5672; chỉ cần biến môi trường khi dùng cấu hình khác. Tài khoản guest không dùng để kết nối từ máy khác; nếu broker ở máy khác cần tài khoản phù hợp.

### 2.2 Biên dịch

```bash
bash build.sh
```

Script tải ba JAR đúng phiên bản vào `lib/`, biên dịch Java và chạy 15 kiểm tra Fibonacci không cần broker. Linux classpath dùng dấu `:`, không dùng `;` và `%CP%` như mẫu Windows.

### 2.3 Chạy server và client

Terminal A, giữ chạy:

```bash
bash run.sh server
```

Terminal B, cũng tại `02_rpc_rabbitmq`:

```bash
bash run.sh client
```

Client mặc định yêu cầu fib(0)..fib(31), giống đề. Các mốc kiểm tra: fib(0)=0, fib(1)=1, fib(10)=55, fib(31)=1346269. Chụp hai terminal, tên gợi ý `rpc_01_fibonacci.png`.

Có thể gọi riêng: `bash run.sh client 10 20 31`.

Sau khi server không-delay đang chạy, kiểm tra tích hợp:

```bash
bash run.sh test
```

Test này cần **RabbitMQ và RPCServer thật**, kiểm tra 32 kết quả, 3 đầu vào lỗi và 3 client đồng thời. Không chạy khi server đang dùng delay 2 giây.

### 2.4 Quan sát queue khi server chậm (câu 8)

1. Dừng server bằng Ctrl+C tại A, đợi process cũ thoát. Không để server nhanh chạy chung.
2. Chạy lại server:

```bash
bash run.sh server --delay-ms 2000
```

3. Mở **3 terminal client riêng**, mỗi terminal chạy:

```bash
bash run.sh client
```

4. Trong terminal thứ 5, quan sát liên tục:

```bash
watch -n 0.5 'bash broker.sh queues'
```

Nếu broker cài trực tiếp thay vì Docker:

```bash
sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged
```

`messages_ready`: request đang chờ giao cho server. `messages_unacknowledged`: request đã giao nhưng server chưa ack. Với một server, prefetch=1, thường thấy một request đang xử lý và những request còn lại chờ. Mỗi client đồng bộ chỉ có tối đa một request đang chờ tại một thời điểm; vì vậy không mặc định sẽ có 96 request chờ cùng lúc dù mỗi client gọi 32 lần.

Các con số thay đổi theo thời điểm chụp, không điền số cố định vào báo cáo. Chụp server delay, các client và bảng queue khi còn request: `rpc_02_delay_queue.png`. Toàn bộ 3 client ×32 request có thể mất khoảng 192 giây với một server và delay 2 giây/request. Đợi hoàn tất hoặc dừng các client sau khi đã quan sát; nếu dừng sớm thì phải nói rõ.

Khi xong, Ctrl+C server/watch/client rồi:

```bash
bash broker.sh stop
```

`stop` giữ container, không xóa tài nguyên khác. Demo này không tự retry call sau timeout vì có thể làm yêu cầu được thực hiện lại. Callback queue chỉ tồn tại trong phiên kết nối client.

## 3. VLC + NetEm – câu 9–17

### 3.1 Chọn mô hình mạng

**Cách A – hai máy Ubuntu/VM (đúng mô hình đề):** hai máy phải truy cập IP của nhau. Trên cả hai:

```bash
ip -br addr
```

Trên server, xác định interface thực sự đi tới client:

```bash
ip route get IP_CLIENT
ping -c 5 IP_CLIENT
```

Trên client `ping -c 5 IP_SERVER`. VM có thể dùng mạng host-only hoặc bridge để hai VM ping được nhau. Đừng giữ nguyên chữ `IP_CLIENT`, `IP_SERVER`, `TEN_GIAO_DIEN` trong lệnh; thay bằng giá trị trên máy bạn. NetEm phải đặt trên server, tại giao diện đi tới client. Khi xem bảng kết quả, ghi rõ hai IP và interface (câu 9).

**Cách B – thử trên một Ubuntu bằng network namespace:** không cần hai VM, nhưng ghi đúng đây là hai đầu mạng logic trên cùng máy.

```bash
cd ../03_video_netem
bash one_host.sh setup
bash one_host.sh status
bash one_host.sh ping
```

Server namespace `ch2-server`: 10.202.0.1; client namespace `ch2-client`: 10.202.0.2. Mỗi namespace có interface riêng tên `eth0`, nối qua veth. NetEm không áp lên card Wi-Fi/Ethernet thật. Nếu kernel/quyền máy không cho tạo namespace thì dùng cách A.

**Lệnh ở các bước sau ghi cho cách A; ngay bên dưới có bản tương ứng cho cách B. Chỉ dùng một mô hình.**

### 3.2 Video mẫu và baseline HTTP theo đề

ZIP đã có `media/sample.ogv` và `media/sample.ts` dài 30 giây, có hình chuyển động và âm thanh. Nếu muốn tự tạo lại, đổi tên/xóa đúng hai file mẫu rồi chạy `bash create_video.sh 60`. Đây là video kiểm thử do ffmpeg sinh, không phải dữ liệu đo.

Trên server, tại `03_video_netem`:

```bash
bash stream_server.sh http media/sample.ogv
```

Trên client, tại thư mục tương ứng:

```bash
bash stream_client.sh http IP_SERVER 1000
```

Cách B, mở **hai terminal**, tại cùng thư mục `03_video_netem`:

```bash
# Terminal server
bash one_host.sh server http "$PWD/media/sample.ogv"
# Terminal client
bash one_host.sh client http 10.202.0.1 1000
```

Không thêm `sudo` trước `one_host.sh server/client`: script vào namespace rồi chuyển lại tài khoản người dùng để VLC không chạy bằng root. Client GUI cần chạy từ terminal trong phiên desktop Ubuntu có DISPLAY/Wayland. Script đặt `--no-one-instance` để VLC không chuyển URL sang một cửa sổ cũ nằm sai namespace.

Xem chất lượng ban đầu: có hình/tiếng, khởi động mất bao lâu, có dừng hình không (câu 10). Chụp `video_01_baseline.png`, ghi vào CSV. Nếu HTTP không mở được, xem log server, kiểm tra ping, cổng 8080, firewall và đảm bảo file OGV có thật. Không sửa NetEm trước khi baseline chạy được.

### 3.3 Delay và giảm cache

Trên server, nạp module nếu cần: `sudo modprobe sch_netem`. Nếu báo thiếu module, kiểm tra kernel/môi trường ảo hóa; không bỏ qua lỗi rồi coi như đã áp dụng NetEm.

Cách A, trên server:

```bash
sudo bash netem.sh TEN_GIAO_DIEN delay100
ping -c 5 IP_CLIENT
```

Cách B:

```bash
bash one_host.sh netem delay100
bash one_host.sh ping
```

Câu 11: với NetEm ở chiều ra của **một đầu**, RTT ping thường tăng khoảng 100ms so với baseline, không tự động thành 200ms. Chụp cả ping và qdisc: `video_02_delay_ping.png`.

Dừng cửa sổ VLC client rồi mở lại với cache=0 để minh họa giảm đệm (câu 12):

```bash
# Cách A
bash stream_client.sh http IP_SERVER 0
# Cách B
bash one_host.sh client http 10.202.0.1 0
```

`network-caching=0` yêu cầu giảm bộ đệm mạng; không có nghĩa mọi bộ đệm giải mã/phát đều biến mất. So sánh cache1000/cache0, cùng video, cùng thời gian quan sát; chụp minh họa nếu có khác biệt: `video_03_lowcache.png`.

### 3.4 Jitter, mất gói, lặp, lỗi, đảo thứ tự

Giữ server phát. Với cách A, dùng `sudo bash netem.sh TEN_GIAO_DIEN PROFILE`; cách B dùng `bash one_host.sh netem PROFILE`. Ví dụ cách B:

```bash
bash one_host.sh netem jitter
bash one_host.sh netem jitter-corr
bash one_host.sh netem loss01
bash one_host.sh netem loss5
bash one_host.sh netem loss-corr
bash one_host.sh netem loss-corr5
bash one_host.sh netem duplicate1
bash one_host.sh netem duplicate10
bash one_host.sh netem corrupt01
bash one_host.sh netem reorder
```

**Không chạy cả khối liên tiếp rồi mới quan sát.** Áp từng dòng, quan sát 20–30 giây, ghi kết quả và chụp khi cần, rồi mới chuyển trường hợp. Mỗi profile tự đặt lại các hiệu ứng khác về 0 để không vô tình cộng dồn delay và loss.

| Profile | Cấu hình | Đối chiếu đề |
|---|---|---|
| baseline | Không thêm hiệu ứng | Mốc so sánh |
| delay100 | delay 100ms | Câu 11–12 |
| jitter | delay 100ms, biến thiên 10ms | Câu 13 |
| jitter-corr | delay 100ms, biến thiên 10ms, tương quan 25% | Câu 13 |
| loss01 / loss1 / loss5 / loss10 | Mất 0.1 / 1 / 5 / 10% | Câu 14 |
| loss-corr / loss-corr5 | Mất 0.3 / 5%, tương quan 25% | Câu 15 |
| duplicate1 / duplicate10 | Lặp 1 / 10% | Câu 16 |
| corrupt01 / corrupt1 | Lỗi 0.1 / 1% | Đoạn packet corruption của đề |
| reorder | delay 10ms, reorder 25%, tương quan 50% | Câu 17 |

Nếu không thấy ảnh hưởng ở mức thấp, giữ nguyên ghi nhận đó và thử mức cao hơn. Ví dụ 0.1% packet loss không nhất thiết làm video hỏng thấy rõ. Không dùng ảnh đứng yên để khẳng định chắc chắn đã đo được giật: nên lưu thêm video quay màn hình ngắn hoặc ghi log/thời điểm quan sát nếu được phép nộp.

Xem thống kê NetEm:

```bash
# Cách A
sudo bash netem.sh TEN_GIAO_DIEN show
# Cách B
bash one_host.sh netem show
```

### 3.5 Phân biệt HTTP và UDP

Lệnh của đề dùng `access=http` nên chạy trên TCP: TCP có thể truyền lại và sắp lại dữ liệu, làm mất/lặp/đảo thứ tự gói biểu hiện thành tăng thời gian đợi hoặc dừng phát, không nhất thiết thành khung hình hỏng. Đừng kết luận “NetEm không chạy” chỉ vì video vẫn xem được.

Nếu muốn thử UDP như phần mô tả của đề, dừng hai VLC cũ và chạy thêm **một thí nghiệm riêng**, dùng file TS:

```bash
# Cách A: server gửi tới IP CLIENT, không phải IP server
bash stream_server.sh udp media/sample.ts IP_CLIENT
# Cách A: client
bash stream_client.sh udp ignored 0
```

Cách B:

```bash
# Server terminal
bash one_host.sh server udp "$PWD/media/sample.ts" 10.202.0.2
# Client terminal
bash one_host.sh client udp ignored 0
```

Ở UDP nên mở client trước rồi bắt đầu phát để dễ thấy giai đoạn đầu. Chạy lại từng profile, ghi riêng protocol=udp trong CSV. Đây là phần bổ sung, không thay thế âm thầm thí nghiệm HTTP theo lệnh mẫu. UDP không tự ưu tiên trên Internet và không tự cung cấp điều khiển tắc nghẽn; không dùng các phát biểu đó trong báo cáo.

### 3.6 Dọn dẹp

Dừng VLC ở cả hai phía trước. Cách A:

```bash
sudo bash netem.sh TEN_GIAO_DIEN reset
```

Cách B:

```bash
bash one_host.sh netem reset
bash one_host.sh cleanup
```

`reset` chỉ xóa qdisc NetEm có handle `20:` do script đặt; hệ thống khôi phục qdisc mặc định. Script không lưu/khôi phục một cấu hình QoS tự chỉnh từ trước; nó từ chối ghi đè root qdisc lạ. Trên hai máy thật, chọn đúng interface trước khi chạy vì NetEm tác động lưu lượng ra qua interface đó.
