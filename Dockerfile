FROM golang:1.17-alpine3.14 AS build-env

WORKDIR /tmp/workdir

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build 

FROM alpine:3.15.1

EXPOSE 8080

RUN apk add --no-cache ca-certificates=~20191127-r5 iwatch=0.2.2-r0

COPY --from=build-env /tmp/workdir/static /app/static
COPY --from=build-env /tmp/workdir/podinfo /app/podinfo

WORKDIR /app

CMD ["./podinfo"]