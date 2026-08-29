FROM golang:1.26 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends libvips-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN CGO_ENABLED=1 go build -mod=vendor -o change-wallpaper .

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libvips42 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/change-wallpaper /usr/local/bin/change-wallpaper
ENTRYPOINT ["change-wallpaper"]
