ARG version=latest

FROM alpine:$version

RUN apk update && \
 apk add bash tcpdump iperf iperf3 nmap bind net-snmp fping && \
 rm -rf /var/cache/apk/*

EXPOSE 5001/tcp
EXPOSE 5001/udp
EXPOSE 5201/tcp
EXPOSE 5201/udp
EXPOSE 162/tcp
EXPOSE 162/udp

COPY entrypoint.sh /entrypoint.sh
COPY help.txt /help.txt
ENTRYPOINT ["/entrypoint.sh"]
