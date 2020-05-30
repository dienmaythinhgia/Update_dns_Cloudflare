#!/bin/bash
# cfIP
# Update dynamic IP for DNS records A on cloudflare
# © 2020 LNT <lnt@ly-le.info>
# version 20200501
#
AUTH_EMAIL='email cua ban'
AUTH_KEY='API totken cua ban'
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
