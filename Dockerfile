# Use updated Go version
FROM golang:1.22-alpine3.18 AS build-env

WORKDIR /tmp/workdir

COPY . .

# Build Go binary statically
RUN CGO_ENABLED=0 GOOS=linux go build -o podinfo

# Use a slim runtime image
FROM alpine:3.18

EXPOSE 8080

# Install necessary runtime packages
RUN apk add --no-cache ca-certificates iwatch

# Copy built binary and static assets
COPY --from=build-env /tmp/workdir/static /app/static
COPY --from=build-env /tmp/workdir/podinfo /app/podinfo

WORKDIR /app

CMD ["./podinfo"]
