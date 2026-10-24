# Bài thực hành chương 1: KVSS và microservices

Hai phần độc lập. `kvss/` thực hiện giao thức TCP dạng dòng của đề; `microservices/` chạy ba dịch vụ HTTP trên Minikube. Chạy lệnh trong đúng thư mục được nêu. Cần tự chụp màn hình và bắt gói trên máy thực hành; các file này không chứa ảnh chụp giả lập.

## 1. KVSS

Yêu cầu Python 3.9 trở lên. Trong hai cửa sổ terminal Ubuntu:

```bash
cd kvss
python3 server.py
```

```bash
cd kvss
python3 client.py
```

Gõ `PUT user42 Alice`, `GET user42`, `STATS`, `DEL user42`, `QUIT` trong client. Client tự thêm `KV/1.0`; cũng chấp nhận dòng đầy đủ như `KV/1.0 GET user42`. Để thử request **thiếu phiên bản**, dùng `nc 127.0.0.1 5050` và nhập `GET user42` trực tiếp (dự kiến `426 UPGRADE_REQUIRED`). `telnet 127.0.0.1 5050` cũng dùng được. Mỗi thông điệp kết thúc bằng LF; server nhận thêm CRLF để tiện thử bằng telnet.

Kiểm thử tự động (10 ca thực hiện qua socket TCP thật):

```bash
cd kvss
python3 -m unittest discover -s tests -v
```

Các quyết định ở những chỗ đề chưa chốt: `PUT` tạo khóa mới trả `201 CREATED`; cập nhật khóa cũ trả `200 OK`. Tên khóa và giá trị phải khác rỗng, không chứa khoảng trắng; ký tự Unicode vẫn dùng được vì thông điệp mã UTF-8. Lệnh sai hoặc sai số tham số trả `400 BAD_REQUEST`; thiếu/sai token phiên bản trả `426 UPGRADE_REQUIRED`. `DEL` lần thứ hai trả `404 NOT_FOUND`. Chỉ một kết nối được xử lý tại một thời điểm theo baseline đơn luồng của đề. `served` đếm các dòng yêu cầu đã xử lý, kể cả lỗi; đọc `STATS` không sửa kho dữ liệu nhưng số đếm và uptime tiếp tục thay đổi.

Để quan sát bằng Wireshark, chạy server và `nc` trên **cùng Ubuntu**, chọn giao diện `lo`, đặt display filter `tcp.port == 5050`, gửi `KV/1.0 PUT user42 Alice` rồi `KV/1.0 GET user42`. Mở Follow TCP Stream để thấy các dòng yêu cầu/phản hồi. TCP là luồng byte: một dòng có thể trải trên nhiều segment và nhiều dòng có thể nằm trong một segment; không kết luận ranh giới dòng từ số packet quan sát được. Lưu ảnh và tệp `.pcapng` từ phiên bạn thực sự chạy.

## 2. Microservices trên Minikube

Cài Docker, `minikube`, `kubectl`. Trên Windows có thể dùng PowerShell; bật Docker Desktop với Linux containers. Lệnh bên dưới dùng Minikube với Docker driver, không cần đăng ảnh lên registry. Chạy trong `microservices/`:

```bash
minikube start --driver=docker
minikube addons enable ingress
minikube image build -t micro-lab-echo:1.0 .
kubectl create namespace micro-lab
kubectl apply -n micro-lab -f k8s/users-deploy.yaml
kubectl apply -n micro-lab -f k8s/catalog-deploy.yaml
kubectl apply -n micro-lab -f k8s/orders-deploy.yaml
kubectl apply -n micro-lab -f k8s/gateway-ingress.yaml
kubectl -n micro-lab rollout status deployment/users-deploy
kubectl -n micro-lab rollout status deployment/catalog-deploy
kubectl -n micro-lab rollout status deployment/orders-deploy
kubectl -n micro-lab get pods -o wide
kubectl -n micro-lab get svc,ingress
```

Mở **terminal riêng** chạy `minikube tunnel`, giữ lệnh chạy. Với Minikube Docker driver trên Windows, thử truy cập Ingress qua `127.0.0.1`; thêm `127.0.0.1 micro.local` vào file `C:\Windows\System32\drivers\etc\hosts` bằng editor chạy quyền quản trị. Nếu driver dùng VM và địa chỉ của Ingress là Minikube IP có thể truy cập trực tiếp, dùng `<MINIKUBE_IP> micro.local` thay thế, với IP lấy từ `minikube ip`.

```bash
curl -H "Host: micro.local" http://127.0.0.1/users
curl -H "Host: micro.local" http://127.0.0.1/catalog
curl -H "Host: micro.local" http://127.0.0.1/orders
```

Trên PowerShell, dùng `curl.exe` thay `curl`. Nếu tunnel/hosts không hoạt động trên máy, có thể kiểm tra luồng Ingress mà không cần sửa hosts bằng lệnh dưới đây (chạy ở terminal riêng), rồi gọi port 8081:

```bash
kubectl -n ingress-nginx port-forward service/ingress-nginx-controller 8081:80
curl -H "Host: micro.local" http://127.0.0.1:8081/users
```

Scale và xác nhận ba Pod `catalog`:

```bash
kubectl -n micro-lab scale deployment/catalog-deploy --replicas=3
kubectl -n micro-lab rollout status deployment/catalog-deploy
kubectl -n micro-lab get pods -l app=catalog -o wide
```

Gọi `/catalog` nhiều lần bằng các kết nối mới; phản hồi JSON có trường `hostname` của Pod. Các hostname *có thể* khác nhau giữa các lần gọi; Kubernetes Service không bảo đảm một chuỗi ngắn request phải lần lượt đi qua mọi Pod. Nếu muốn biết chắc các Pod đều nhận traffic, xem danh sách Pod và log của từng Pod bằng `kubectl -n micro-lab logs <ten-pod>`.

Kết thúc, xóa tài nguyên đã tạo:

```bash
kubectl -n micro-lab delete -f k8s/gateway-ingress.yaml
kubectl -n micro-lab delete -f k8s/users-deploy.yaml -f k8s/catalog-deploy.yaml -f k8s/orders-deploy.yaml
kubectl delete namespace micro-lab
```

Lưu ý: bốn liên kết Dropbox trong PDF không thể đọc trong phiên chuẩn bị này. Các YAML đi kèm là bản cài đặt **mới**, thống nhất với mục tiêu của đề; không được nhận là nội dung gốc của các liên kết đó. Theo YAML của project này, `users-deploy` có 1 replica ban đầu và Service loại `ClusterIP`. Trả lời câu 7 theo đúng YAML bạn thực sự nộp/chạy. Ảnh chụp cho câu 6 và mô tả Wireshark cho câu 4 phải dựa trên kết quả bạn tự quan sát.
