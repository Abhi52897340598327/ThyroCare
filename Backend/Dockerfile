# syntax=docker/dockerfile:1

FROM node:22-alpine AS dashboard-build
WORKDIR /dashboard
COPY Dashboard/package*.json ./
RUN npm ci || npm install
COPY Dashboard ./
RUN npm run build

FROM swift:6.0-jammy AS build
WORKDIR /build
COPY Package.swift ./
COPY Sources ./Sources
COPY Tests ./Tests
COPY Public ./Public
COPY Resources ./Resources
RUN swift package resolve
RUN swift build -c release --product Run --static-swift-stdlib

FROM ubuntu:22.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive
ENV HOST=0.0.0.0
ENV PORT=8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libatomic1 \
        libcurl4 \
        libjemalloc2 \
        libxml2 \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 vapor

WORKDIR /app

COPY --from=build /build/.build/release/Run /app/App
COPY --from=build /build/Public /app/Public
COPY --from=build /build/Resources /app/Resources
COPY --from=dashboard-build /dashboard/out /app/Public

RUN chown -R vapor:vapor /app

USER vapor

EXPOSE 8080

ENTRYPOINT ["/app/App"]
