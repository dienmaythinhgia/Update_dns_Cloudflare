# Update_dns_Cloudflare
Script giúp cập nhật IP của domain và nhiều subdomain trên cloudflare.com một cách tự động với cú pháp đơn giản.
Cú pháp của script như sau:
```
Update_dns_Cloudflare [-f] mydomain.com subdomain[,subdomain2...]
    -f: xóa cache/buộc cập nhật
    subdomain: có thể là sub thay cho sub.mydomain.com, hay
    @: thay cho mydomain.com, hay
    *: thay cho tất cả subdomain trừ ra @
    -subA: ngoại trừ subA
  ```
  
  Thí dụ
```
Update_dns_Cloudflare mydomain.com @,\*        # Update IP cho mọi record A
Update_dns_Cloudflare mydomain.com @,mail,mx   # Update IP cho @, subdomain mail và mx
Update_dns_Cloudflare mydomain.com -f \*       # xóa cache và cập nhật cho mọi subdomain
Update_dns_Cloudflare mydomain.com \*,-mx      # update mọi subdomain, trừ mx
```
Số lần gọi hàm API của cloudflare.com để cập nhật n record A là từ 0 đến n+2, so với cách gọi thông thường là từ 0 đến 2n+1, nghĩa là nhanh hơn và ít lần gọi hàm hơn khi n > 1.

cloudflare.com không thích khách hàng tạo script update DNS record tự động, vì nó làm server bận rộn và chậm đi một cách không mong muốn. Cloudflare đã từng nhiều lần ngưng hỗ trợ các lời gọi cập nhật IP, và hiện nay đã đưa ra hạn chế về số lần gọi API trong 24h và trong tháng cho mỗi tài khoản.

Script này giúp cập nhật IP an toàn, không phạm luật, cho tối đa 10 domain x 10 DNS record A trong mỗi 3 phút (khoảng 2000 lần gọi hàm API trong 1 giờ), tuy rằng trên thực tế có thể không gọi hàm nào trong suốt nhiều ngày vì IP không thay đổi.

Vì hàm API của cloudflare trả về chuổi JSON nên chúng ta cần cài đặt con-dao-Thụy-Sĩ cho JSON là jq

sudo apt install jq
Toàn bộ script và chú thích
```
#!/bin/bash
# cfIP
# Update dynamic IP for DNS records A on cloudflare
# © 2020 LNT <lnt@ly-le.info>
# version 20200501
#
AUTH_EMAIL='your_login_email'
AUTH_KEY='your_auth_key_32_characters'
BASE_URL='https://api.cloudflare.com/client/v4/zones'
GETWAN='http://icanhazip.com'
# Shared Memory
SHM=/dev/shm/cfIP
[ -d $SHM ] || mkdir $SHM
[ '-f' = "$1" ] && { rm -f $SHM/*; ff=1; shift; } || ff=0
set -f
if [ $# -ne 2 ]; then
  echo
  echo 'Update the IP of domain/subdomain for cloudflare.com'
  echo "usage: $(basename $0) [-f] yr_domain sub[,sub2 ...]"
  echo '       -f:  clear cache'
  echo '       sub: instead of sub.yr_domain'
  echo '       @:   instead of yr_domain'
  echo '       \*:  all subdomains except @'
  echo '      -sub: exclude sub'
  exit 1
fi
DOMAIN="$1"
PARAMS="$2"
hbk=$(md5sum <<< "$PARAMS" | awk '{print $1}')
# wan IP
wIP=$(curl -s "$GETWAN")
[ -f "$SHM/ip" ] && oIP=$(<$SHM/ip) || oIP=''
printf $wIP > $SHM/ip
# force update?
[[ $ff -eq 0 && "$wIP" = "$oIP" ]] && { echo "IP has not changed"; exit 0; }
# Read from backup
if [[ -f $SHM/"$hbk" ]]; then
  hosts=$(<$SHM/"$hbk")
  ZONE_ID=$(<$SHM/$DOMAIN)
  BASE_URL="${BASE_URL}"/"${ZONE_ID}"/dns_records
else
  # ID of domain
  ZONE_ID=$(jq -r '.result[].id' <<< $(curl -s -H "X-Auth-Email: ${AUTH_EMAIL}" -H "X-Auth-Key: ${AUTH_KEY}" -H "Content-Type: application/json" -X GET ${BASE_URL}?name=${DOMAIN}&status=active))
  [[ "${ZONE_ID}" =~ ^[0-9a-f]{32}$ ]] || { echo "Bad Zone ID"; exit 1; }
  echo "${ZONE_ID}" > $SHM/$DOMAIN
  BASE_URL="${BASE_URL}"/"${ZONE_ID}"/dns_records
  # json string of subdomain
  tmp=$(curl -s -H "X-Auth-Email: ${AUTH_EMAIL}" -H "X-Auth-Key: ${AUTH_KEY}" -H "Content-Type: application/json" -X GET "${BASE_URL}?type=A" | jq -r '.result[] | {id,name,content}' | jq -s .)
  # All subdomains
  if [[ $PARAMS = *\** ]]; then
    ra=($(echo $PARAMS | grep -Po '(?<=-)[^,]+' | jq -Rr ". + \".$DOMAIN\""))
    [[ ! $PARAMS = *@* ]] && ra+=($DOMAIN)
    c=''; for a in "${ra[@]}"; do [ ! "$c" ] && c=".name == \"$a\"" || c="$c or .name == \"$a\""; done
    hosts=$(echo "$tmp" | jq ".[] | del(select($c)" | jq -s .)
  else
    aa=($(echo $PARAMS | grep -Po '(?<!-)[^,]+' | jq -Rr ". + \".$DOMAIN\""))
    aa=("${aa[@]/@./}")
    c=''; for a in "${aa[@]}"; do [ ! "$c" ] && c=".name == \"$a\"" || c="$c or .name == \"$a\""; done
    hosts=$(echo "$tmp" | jq ".[] | select($c)" | jq -s .)
  fi
  echo "$hosts" > $SHM/$hbk
fi
# Update IP
echo "$hosts" | jq -r '.[] | [.id, .name, .content] | @tsv' |
while IPS=$'\t' read id name cIP; do
  if [[ $ff -eq 0 && "$wIP" == "$cIP" ]]; then
    ret='IP has not changed'
  else
    ret=$(curl -s -X PUT -H "X-Auth-Email: ${AUTH_EMAIL}" -H "X-Auth-Key: ${AUTH_KEY}" -H "Content-Type: application/json" "${BASE_URL}/$id" --data "{\"type\":\"A\",\"name\":\"$name\",\"content\":\"${wIP}\",\"ttl\":3600,\"proxied\":false}" | jq -r '.success')
  fi
  echo "Updated IP for $name: $ret"
done
```

Chú thích

-f xóa cache /buộc cập nhật, đặt đầu tiên trên dòng lệnh
* thay cho tất cả subdomain
@ thay cho domain chính
– đứng trước subdomain chỉ định không cập nhật subdomain đó
Cần escape dấu * trên dòng lệnh thành \*
