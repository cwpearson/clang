# Stage 1: Build environment
FROM docker.io/redhat/ubi8 AS builder

ARG CMAKE_VERSION
ARG CLANG_VERSION

RUN if [ -z "$CMAKE_VERSION" ]; then echo "CMAKE_VERSION build argument is required" && exit 1; fi
RUN if [ -z "$CLANG_VERSION" ]; then echo "CLANG_VERSION build argument is required" && exit 1; fi

RUN dnf install -y \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    python3 \
    wget \
    xz \
    && dnf clean all

RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
  && tar -xf cmake-${CMAKE_VERSION}.tar.gz \
  && rm cmake-${CMAKE_VERSION}.tar.gz
RUN ( cd cmake-${CMAKE_VERSION} && ./bootstrap --prefix=/opt/cmake --parallel=$(nproc) ) \
 && ( cd cmake-${CMAKE_VERSION} && make -j$(nproc) install ) \
 && rm -rf cmake-${CMAKE_VERSION}
ENV PATH="/opt/cmake/bin:${PATH}"

RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-${CLANG_VERSION}/llvm-project-${CLANG_VERSION}.src.tar.xz \
  && tar -xf llvm-project-${CLANG_VERSION}.src.tar.xz \
  && rm llvm-project-${CLANG_VERSION}.src.tar.xz
RUN cmake -S llvm-project-${CLANG_VERSION}.src/llvm -B build \
  -DCMAKE_INSTALL_PREFIX=/opt/llvm \
  -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra' \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DLLVM_TARGETS_TO_BUILD="X86"
RUN cmake --build build --parallel $(nproc) --target install \
 && rm -rf build

## stage 2: final image
FROM docker.io/redhat/ubi8

RUN dnf install -y \
    gcc \
    gcc-c++ \
    make \
    openssl \
    xz \
    && dnf clean all

# keep cmake
COPY --from=builder /opt/cmake /usr/local
# keep clang binaries
COPY --from=builder /opt/llvm/bin /usr/local/bin
COPY --from=builder /opt/llvm/lib /usr/local/lib

LABEL maintainer="Carl Pearson <me@carlpearson.net>"
LABEL org.opencontainers.image.title="clang"
LABEL description="A container with clang and cmake"
LABEL org.opencontainers.image.description="A container with clang and cmake"
LABEL org.opencontainers.image.source https://github.com/cwpearson/clang
LABEL org.opencontainers.image.licenses="GPLv3"
# LABEL version="1.0"
# LABEL org.opencontainers.image.version="1.0"
# LABEL org.opencontainers.image.url="https://example.com"
# LABEL org.opencontainers.image.documentation="https://example.com/docs"
# LABEL org.opencontainers.image.vendor="Example Corp"

