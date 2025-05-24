FROM alpine:3.16

RUN apk add --no-cache bash iptables jq

WORKDIR /app

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]