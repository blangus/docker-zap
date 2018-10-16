#!/usr/bin/env bash

CONTAINER_ID=$(docker run -u zap -p 2375:2375 -d owasp/zap2docker-weekly zap.sh -daemon -port 2375 -host 0.0.0.0 -config api.disablekey=true -config scanner.attackOnStart=true -config view.mode=attack -config connection.dnsTtlSuccessfulQueries=-1 -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true)

# the target URL for ZAP to scan
TARGET_URL=$1

docker exec $CONTAINER_ID zap-cli -p 2375 status -t 120 && docker exec $CONTAINER_ID zap-cli -p 2375 open-url $TARGET_URL

docker exec $CONTAINER_ID zap-cli -p 2375 spider $TARGET_URL

docker exec $CONTAINER_ID zap-cli -p 2375 active-scan -r $TARGET_URL

docker exec $CONTAINER_ID zap-cli -p 2375 alerts

# docker logs [container ID or name]
divider==================================================================
printf "\n"
printf "$divider"
printf "ZAP-daemon log output follows"
printf "$divider"
printf "\n"

docker logs $CONTAINER_ID

# export html or xml report
case $2 in
--xmlreport ) echo "printing xml report"
              wget -O report.xml 172.17.0.1:2375/OTHER/core/other/xmlreport/?formMethod=GET
              ;;

* ) echo "printing http report"
    wget -O report.html 172.17.0.1:2375/OTHER/core/other/htmlreport/?formMethod=GET
    ;;
esac


docker stop $CONTAINER_ID || true && docker rm $CONTAINER_ID || true