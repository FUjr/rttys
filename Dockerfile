FROM node:12 AS ui
WORKDIR /rttys-ui
COPY ui .
RUN npm install && npm run build

FROM golang:latest AS rttys
WORKDIR /rttys-build
COPY . .
COPY --from=ui /rttys-ui/dist ui/dist
RUN CGO_ENABLED=0 \
    VersionPath="rttys/version" \
    go build -ldflags="-s -w "

FROM alpine:latest
COPY --from=rttys /rttys-build/rttys /usr/bin/rttys
ENTRYPOINT ["/usr/bin/rttys"]
