ARG version=latest

FROM alpine:$version

RUN apk update && \
 apk add bash tcpdump iperf nmap && \
 rm -rf /var/cache/apk/*

EXPOSE 5001/tcp
EXPOSE 5001/udp

COPY entrypoint.sh /entrypoint.sh
COPY help.txt /help.txt
ENTRYPOINT ["/entrypoint.sh"]
