ARG version=latest

FROM alpine:$version

RUN apk update && \
 apk add bash tcpdump iperf nmap && \
 rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
