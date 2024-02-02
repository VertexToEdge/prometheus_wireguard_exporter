ARG BUILDPLATFORM=linux/amd64

ARG ALPINE_VERSION=3.14
ARG RUST_VERSION=1.75.0-slim

FROM --platform=${BUILDPLATFORM} rust:${RUST_VERSION} AS build
WORKDIR /usr/src/prometheus_wireguard_exporter
COPY . .
RUN cargo build --release


FROM alpine:${ALPINE_VERSION}
EXPOSE 9586/tcp
WORKDIR /usr/local/bin
RUN apk add --no-cache --q tini && \
  rm -rf /var/cache/apk/*
RUN adduser prometheus-wireguard-exporter -s /bin/sh -D -u 1000 1000 && \
  mkdir -p /etc/sudoers.d && \
  echo 'prometheus-wireguard-exporter ALL=(root) NOPASSWD:/usr/bin/wg show * dump' > /etc/sudoers.d/prometheus-wireguard-exporter && \
  chmod 0440 /etc/sudoers.d/prometheus-wireguard-exporter
RUN apk add --update -q --no-cache wireguard-tools-wg sudo
USER prometheus-wireguard-exporter
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/prometheus_wireguard_exporter"]
CMD [ "-a" ]
COPY --from=build --chown=prometheus-wireguard-exporter /usr/src/prometheus_wireguard_exporter/target/release/prometheus_wireguard_exporter ./prometheus_wireguard_exporter