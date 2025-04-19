FROM golang:1.18-alpine3.14 AS build-env

WORKDIR /tmp/workdir

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o podinfo

FROM alpine:3.15.1

EXPOSE 8080

# Install latest available versions without pinning
RUN apk add --no-cache ca-certificates iwatch

COPY --from=build-env /tmp/workdir/static /app/static
COPY --from=build-env /tmp/workdir/podinfo /app/podinfo

WORKDIR /app

CMD ["./podinfo"]
