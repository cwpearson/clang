# clang-tidy

## Quick Run

```bash
cd your/source/tree
podman run --rm -v "${PWD}"/src ghcr.io/cwpearson/clang-tidy-16:latest clang-tidy ...
```

Inside the container, the working directory is /src, we use the volume mount to map the host working directory `${PWD}` into `/src`: `-v "${PWD}"/src`.

## Building the Image Locally

```bash
export CMAKE_VERSION=3.25.3
export CLANG_VERSION=16.0.6
podman build -f clang-tidy-16.dockerfile \
  --build-arg CMAKE_VERSION=${CMAKE_VERSION} --build-arg CLANG_VERSION=${CLANG_VERSION} \
   -t clang:${CLANG_VERSION}-cmake${CMAKE_VERSION}
```



## Deploy

1. Create a "personal access token (classic)" with `write:packages`
  * account > settings > developer settings > personal access tokens
2. Put that personal access token as the repository secret `GHCR_TOKEN`.
