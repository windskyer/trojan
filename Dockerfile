ARG TARGETOS=linux
ARG TARGETARCH=arm64

# Build the manager binary
FROM golang:1.17 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
# RUN go mod download

# Copy the go source
COPY asset/ asset/
COPY cmd/ cmd/
COPY core/ core/
COPY trojan/ trojan/
COPY util/ util/
COPY vendor/ vendor/
COPY web/ web/
COPY main.go main.go
COPY .git/ .git/

RUN export VERSION=`git describe --tags $(git rev-list --tags --max-count=1)`
RUN export NOW=`TZ=Asia/Shanghai date "+%Y%m%d-%H%M"`
RUN export GO_VERSION=`go version|awk '{print $3,$4}'`
RUN export GIT_VERSION=`git rev-parse HEAD`
RUN export LDFLAGS="-w -s -X 'trojan/trojan.MVersion=$VERSION' -X 'trojan/trojan.BuildDate=$NOW' -X 'trojan/trojan.GoVersion=$GO_VERSION' -X 'trojan/trojan.GitVersion=$GIT_VERSION'"

RUN CGO_ENABLED=0 GOOS=${TARGETOS:-$(go env GOOS)} GOARCH=${TARGETARCH:-$(go env GOARCH)} go build -ldflags "$LDFLAGS" -o trojan-cmd .

FROM flftuu/trojan-cmd:v1.0.0
WORKDIR /
USER 0:0

COPY --from=builder /workspace/trojan-cmd /trojan-cmd
CMD ["./trojan-cmd", "web"]
