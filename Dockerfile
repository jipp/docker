ARG version=3.12.3

FROM alpine:$version

RUN apk update && \
 apk add bash tcpdump iperf nmap && \
 rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

