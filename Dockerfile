FROM golang:1.21.0-bullseye
ARG TARGETOS
ARG TARGETARCH
ARG KUBE_VERSION="1.28.0"
ARG CODEGEN_VERSION="v0.28.0"
ARG CONTROLLER_GEN_VERSION="0.12.1"

ENV OS=${TARGETOS}
ENV ARCH=${TARGETARCH}

RUN apt-get update && \
    apt-get install -y \
    git \
    unzip

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOBIN=/usr/bin go install k8s.io/code-generator/cmd/...@${CODEGEN_VERSION} && \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOBIN=/usr/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v${CONTROLLER_GEN_VERSION}

COPY hack/install-protoc.sh /go/install-protoc.sh
COPY hack/k8s-validation_exceptions.list /go/k8s-validation_exceptions.list
RUN /go/install-protoc.sh
ENV PATH="${PATH}:/go/protoc"

# Create user
ARG uid=1000
ARG gid=1000
RUN addgroup --gid $gid codegen && \
    adduser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --uid $uid --ingroup codegen codegen && \
    chown codegen:codegen -R /go

COPY hack /hack
RUN chown codegen:codegen -R /hack && \
    mv /hack/update* /usr/bin

USER codegen

WORKDIR /usr/bin