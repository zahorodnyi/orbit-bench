FROM rust:1-slim-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends linux-perf time perl git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 https://github.com/brendangregg/FlameGraph /opt/FlameGraph

ENV FLAMEGRAPH_DIR=/opt/FlameGraph
WORKDIR /work
