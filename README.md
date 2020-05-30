## Update dns_Cloudflare
php giúp cập nhật IP của domain trên cloudflare.com một cách tự động trên Centos với cú pháp đơn giản.
Cú pháp của script như sau:
```
php cloudf_dns.php mail_cua_ban@gmail.com API_Totken ten_mien.com

  ```
  
  Thí dụ
```
php cloudf_dns.php votrunghantvbox@gmail.com 77c9f23b3fb4d3eeb15e5d2566f396c387135 muavaban.com

```
# Cập nhật mỗi khi khởi động
Để tự động chạy một script sau khi server linux khởi động xong hãy sử dụng  ``#nano /etc/rc.local``

/etc/rc.local chứa script để chạy tự động sau khi hệ thống boot xong.

Thông thường khi toàn bộ các dịch vụ của hệ thống đã chạy, bạn muốn chạy một số lệnh tự động hoặc gọi script nào đó thì hãy thêm vào file /etc/rc.local
# Ví dụ:
```
nano -w /etc/rc.local
```
- Nhập nội dung nhu sau:
```
php cloudf_dns.php votrunghantvbox@gmail.com 77c9f23b3fb4d3eeb15e5d2566f396c387135 muavaban.com

php cloudf_dns.php votrunghantvbox@gmail.com 77c9f23b3fb4d3eeb15e5d2566f396c387135 sangtao.top

```
## Tao: ``crontab -e`` để tạo lịch tự cập nhật
Ví dụ 30 phút cập nhật 1 lần:
```crontab -e```
sau đó dùng lệnh nhập nội dung như sau:
```
0,30 * * * * php cloudf_dns.php votrunghantvbox@gmail.com 77c9f23b3fb4d3eeb15e5d2566f396c387135 muavaban.top 
```
Sau đó lưu lại.

