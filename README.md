# Update_dns_Cloudflare
Script giúp cập nhật IP của domain và nhiều subdomain trên cloudflare.com một cách tự động với cú pháp đơn giản.
Cú pháp của script như sau:
///
cfIP [-f] mydomain.com subdomain[,subdomain2...]
    -f: xóa cache/buộc cập nhật
    subdomain: có thể là sub thay cho sub.mydomain.com, hay
    @: thay cho mydomain.com, hay
    *: thay cho tất cả subdomain trừ ra @
    -subA: ngoại trừ subA
    ///
