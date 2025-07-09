# https://just.systems/man/en/

[private]
@default:
	just --list --unsorted

# Run linter.
@lint:
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/shellcheck
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/hadolint
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/yamllint
	docker run --rm --read-only --volume=$(pwd):$(pwd):rw --workdir=$(pwd) kokuwaio/markdownlint --fix
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/renovate-config-validator
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) woodpeckerci/woodpecker-cli lint

# Build image with local docker daemon.
build:
	docker build . --target=dockerd				--tag=kokuwaio/dockerd:dev
	docker build . --target=dockerd-rootless	--tag=kokuwaio/dockerd:dev-rootless
	docker build . --target=cli					--tag=kokuwaio/docker-cli:dev
	docker build . --target=cli-git				--tag=kokuwaio/docker-cli:dev-git
	docker build . --target=cli-az				--tag=kokuwaio/docker-cli:dev-az
	docker build . --target=cli-az-git			--tag=kokuwaio/docker-cli:dev-az-git

# Inspect image layers with `dive`.
dive TARGET="dockerd":
	dive build . --target={{TARGET}}

# Run dockerd and use docker cli to execute bash.
run TARGET="dockerd-rootless":
	docker build . --target=dockerd-rootless --tag=kokuwaio/dockerd:dev
	docker rm kokuwaio-dockerd --force
	docker run --name=kokuwaio-dockerd --rm --privileged --env=DOCKERD_LOG_LEVEL=info --env=DOCKERD_REGISTRY_MIRROR=https://mirror.kokuwa.io --publish=2375:2375 kokuwaio/dockerd:dev &
	sleep 2
	DOCKER_HOST=tcp://127.0.0.1:2375 docker run --rm bash uname -r
	docker rm kokuwaio-dockerd --force
