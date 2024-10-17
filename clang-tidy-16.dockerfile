# Stage 1: Build environment
FROM docker.io/redhat/ubi8 AS builder

RUN dnf install -y \
    cmake \
    gcc \
    gcc-c++ \
    python3 \
    wget \
    xz \
    && dnf clean all

RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.6/llvm-project-16.0.6.src.tar.xz \
    && tar -xf llvm-project-16.0.6.src.tar.xz
RUN cmake -S llvm-project-16.0.6.src/llvm -B build \
  -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra' \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DLLVM_TARGETS_TO_BUILD=""
RUN cmake --build build --target clang-tidy --parallel $(nproc)

# base final image off ubi8-micro
FROM docker.io/redhat/ubi8-micro

LABEL maintainer="Carl Pearson <me@carlpearson.net>"
LABEL org.opencontainers.image.title="clang-tidy 16"
LABEL description="A container with clang-tidy 16"
LABEL org.opencontainers.image.description="A container with clang-tidy 16"
LABEL org.opencontainers.image.source https://github.com/cwpearson/clang-tidy
LABEL org.opencontainers.image.licenses="GPLv3"
# LABEL version="1.0"
# LABEL org.opencontainers.image.version="1.0"
# LABEL org.opencontainers.image.url="https://example.com"
# LABEL org.opencontainers.image.documentation="https://example.com/docs"
# LABEL org.opencontainers.image.vendor="Example Corp"

# clang-tidy-16 links this
COPY --from=builder /lib64/libstdc++.so.6 /lib64/libstdc++.so.6
# keep clang-tidy binary only
COPY --from=builder /build/bin/clang-tidy /usr/local/bin/clang-tidy
# also provide clang-tidy-16
RUN ln -s /usr/local/bin/clang-tidy /usr/local/bin/clang-tidy-16

# expect caller to map $PWD into /src with -v flag
WORKDIR /src
