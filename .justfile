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
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) kokuwaio/renovate
	docker run --rm --read-only --volume=$(pwd):$(pwd):ro --workdir=$(pwd) woodpeckerci/woodpecker-cli lint

# Build image with local docker daemon.
@build:
	docker build . --target=dockerd				--tag=kokuwaio/dockerd:dev
	docker build . --target=dockerd-rootless	--tag=kokuwaio/dockerd:dev-rootless
	docker build . --target=cli					--tag=kokuwaio/docker-cli:dev
	docker build . --target=cli-git				--tag=kokuwaio/docker-cli:dev-git
	docker build . --target=cli-az				--tag=kokuwaio/docker-cli:dev-az
	docker build . --target=cli-az-git			--tag=kokuwaio/docker-cli:dev-az-git

# Inspect image with docker.
@inspect IMAGE="dockerd:dev": build
	docker image inspect kokuwaio/{{IMAGE}}

# Inspect image layers with `dive`.
@dive IMAGE="dockerd:dev": build
	dive kokuwaio/{{IMAGE}}
