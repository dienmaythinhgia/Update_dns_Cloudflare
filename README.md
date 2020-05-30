# Update_dns_Cloudflare
php giúp cập nhật IP của domain và nhiều subdomain trên cloudflare.com một cách tự động với cú pháp đơn giản.
Cú pháp của script như sau:
```
php cloudf_dns.php mail_cua_ban@gmail.com API_Totken ten_mien.com IP_Hien_TAI

  ```
  
  Thí dụ
```
php cloudf_dns.php votrunghantvbox@gmail.com 77c9f23b3fb4d3eeb15e5d2566f396c387135 muavaban.top 1.52.242.28

```
Số lần gọi hàm API của cloudflare.com để cập nhật n record A là từ 0 đến n+2, so với cách gọi thông thường là từ 0 đến 2n+1, nghĩa là nhanh hơn và ít lần gọi hàm hơn khi n > 1.


