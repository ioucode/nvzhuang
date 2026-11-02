# codearea 部署镜像:Go 后端 + 同源静态前端(index.html/data.js/assets)
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /out/main .

FROM alpine:3.22
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app
COPY --from=builder /out/main ./main
COPY backend/workflows/ ./workflows/
COPY deploy/codearea.yaml ./manifest/config/config.yaml
COPY index.html data.js ./public/
COPY assets/ ./public/assets/
# 前端默认连同源后端
RUN sed -i 's#<head>#<head><script>window.AI_API_URL=location.origin;</script>#' public/index.html \
    && grep -q 'window.AI_API_URL=location.origin' public/index.html
USER 65532:65532
EXPOSE 8000
CMD ["./main"]
