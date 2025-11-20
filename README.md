# Docker Daemon and CLI for WoodpeckerCI Plugin

[![dockerd pulls](https://img.shields.io/docker/pulls/kokuwaio/dockerd)](https://hub.docker.com/r/kokuwaio/dockerd)
[![dockerd size](https://img.shields.io/docker/image-size/kokuwaio/dockerd)](https://hub.docker.com/r/kokuwaio/dockerd)
[![cli pulls](https://img.shields.io/docker/pulls/kokuwaio/docker-cli)](https://hub.docker.com/r/kokuwaio/docker-cli)
[![cli size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli)](https://hub.docker.com/r/kokuwaio/docker-cli)
[![dockerfile](https://img.shields.io/badge/source-Dockerfile%20-blue)](https://git.kokuwa.io/woodpecker/docker/src/branch/main/Dockerfile)
[![license](https://img.shields.io/badge/License-EUPL%201.2-blue)](https://git.kokuwa.io/woodpecker/docker/src/branch/main/LICENSE)
[![prs](https://img.shields.io/gitea/pull-requests/open/woodpecker/dockerd?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/woodpecker/docker/pulls)
[![issues](https://img.shields.io/gitea/issues/open/woodpecker/dockerd?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/woodpecker/docker/issues)

A [Woodpecker I](https://woodpecker-ci.org) prepared docker daemon and cli.
Also usable with Gitlab, Github or locally, see examples for usage.

## Features

- dockerd: with and without rootlesskit
- dockerd: configures mirror for dockerd
- cli: with buildkit
- cli: [variants](https://hub.docker.com/r/kokuwaio/docker-cli/tags):
  - `git`: with git
  - `az`: with Azure CLI
  - `az-git`: with Azure CLI and git

| Image                                                                      |                                                                     amd64                                                                      |                                                                     arm64                                                                      |
| -------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------: |
| [kokuwaio/dockerd](https://hub.docker.com/r/kokuwaio/dockerd)              | [![size](https://img.shields.io/docker/image-size/kokuwaio/dockerd/latest?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/dockerd)       | [![size](https://img.shields.io/docker/image-size/kokuwaio/dockerd/latest?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/dockerd)       |
| [kokuwaio/dockerd:rootless](https://hub.docker.com/r/kokuwaio/dockerd)     | [![size](https://img.shields.io/docker/image-size/kokuwaio/dockerd/rootless?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/dockerd)     | [![size](https://img.shields.io/docker/image-size/kokuwaio/dockerd/rootless?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/dockerd)     |
| [kokuwaio/docker-cli](https://hub.docker.com/r/kokuwaio/docker-cli)        | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/latest?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli) | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/latest?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli) |
| [kokuwaio/docker-cli:git](https://hub.docker.com/r/kokuwaio/docker-cli)    | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/git?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli)    | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/git?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli)    |
| [kokuwaio/docker-cli:az](https://hub.docker.com/r/kokuwaio/docker-cli)     | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/az?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli)     | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/az?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli)     |
| [kokuwaio/docker-cli:az-git](https://hub.docker.com/r/kokuwaio/docker-cli) | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/az-git?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli) | [![size](https://img.shields.io/docker/image-size/kokuwaio/docker-cli/az-git?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/docker-cli) |

## Example

```yaml
services:
  - name: dockerd
    image: kokuwaio/dockerd
    ports: [2375, 8080]

steps:
  info:
    image: kokuwaio/docker-cli
    commands: docker info
```

## Settings

| Environment               | Default | Description                                                                                       |
| ------------------------- | ------- | ------------------------------------------------------------------------------------------------- |
| DOCKERD_PORT              | `2375`  | Specifies the port to listen on                                                                   |
| DOCKERD_SHUTDOWN_TIMEOUT  | `0`     | Set the default shutdown timeout                                                                  |
| DOCKERD_LOG_LEVEL         | `none`  | Set the [logging level](https://docs.docker.com/reference/cli/dockerd/#log-format)                |
| DOCKERD_REGISTRY_MIRROR   | `none`  | Specifies a list of registry mirrors.                                                             |
| DOCKERD_INSECURE_REGISTRY | `none   | Configure [insecure registry](https://docs.docker.com/reference/cli/dockerd/#insecure-registries) |
