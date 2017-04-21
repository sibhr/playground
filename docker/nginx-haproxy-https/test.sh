#!/bin/bash
CURL_OPT="-k "
echo " ---------------------------------------------------"
echo " Curl haproxy-1-nginx-a.local via haproxy"
curl ${CURL_OPT} -H 'Host: haproxy-1-nginx-a.local' https://127.0.0.1:443

echo " Curl haproxy-1-nginx-b.local via haproxy"
curl ${CURL_OPT} -H 'Host: haproxy-1-nginx-b.local' https://127.0.0.1:443

echo " Curl haproxy-2-nginx-a.local via haproxy"
curl ${CURL_OPT} -H 'Host: haproxy-2-nginx-a.local' https://127.0.0.1:2443

echo " Curl haproxy-2-nginx-b.local via haproxy"
curl ${CURL_OPT} -H 'Host: haproxy-2-nginx-b.local' https://127.0.0.1:2443

echo " ---------------------------------------------------"

echo " Curl haproxy-2-nginx-a.local via haproxy"
curl ${CURL_OPT}   https://haproxy-2-nginx-a.local:2443

echo " Curl haproxy-2-nginx-b.local via haproxy"
curl ${CURL_OPT}  https://haproxy-2-nginx-b.local:2443
