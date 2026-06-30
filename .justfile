# https://just.systems/man/en/

[private]
@default:
    just --list --unsorted

# Run linter on project.
@lint:
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/just:1.55.1
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/shellcheck:v0.11.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/hadolint:v2.14.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/yamllint:v1.38.0
    docker run --rm --read-only --volume=$PWD:$PWD:rw --workdir=$PWD kokuwaio/markdownlint:0.49.0 --fix
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/renovate-config-validator:43
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD woodpeckerci/woodpecker-cli:v3 lint

# Build image with local docker daemon.
@build:
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=dockerd			--tag=kokuwaio/dockerd:dev
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=dockerd-rootless	--tag=kokuwaio/dockerd:dev-rootless
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=cli				--tag=kokuwaio/docker-cli:dev
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=cli-git			--tag=kokuwaio/docker-cli:dev-git
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=cli-az			--tag=kokuwaio/docker-cli:dev-az
    docker buildx build . --platform=linux/amd64,linux/arm64 --target=cli-az-git		--tag=kokuwaio/docker-cli:dev-az-git

# Inspect image layers with `dive`.
dive TARGET="dockerd":
    dive build . --target={{ TARGET }}

# Run dockerd and use docker cli to execute bash.
run TARGET="dockerd-rootless":
    docker build . --target={{ TARGET }} --tag=docker.io/kokuwaio/dockerd:dev
    docker rm kokuwaio-dockerd --force
    docker run --name=kokuwaio-dockerd --rm --privileged --env=DOCKERD_LOG_LEVEL=info --env=DOCKERD_REGISTRY_MIRROR=https://mirror.kokuwa.io --publish=2375:2375 kokuwaio/dockerd:dev &
    sleep 2
    DOCKER_HOST=tcp://127.0.0.1:2375 docker run --rm bash uname -r
    docker rm kokuwaio-dockerd --force
