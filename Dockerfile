# hadolint global ignore=DL3008

##
## Download docker
##

FROM docker.io/library/debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS download
WORKDIR /tmp/docker
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates curl 
ARG TARGETARCH
RUN curl --fail --silent --parallel --remote-name-all \
		"https://download.docker.com/linux/debian/dists/trixie/pool/stable/$TARGETARCH/containerd.io_1.7.28-0~debian.13~trixie_$TARGETARCH.deb" \
		"https://download.docker.com/linux/debian/dists/trixie/pool/stable/$TARGETARCH/docker-buildx-plugin_0.28.0-0~debian.13~trixie_$TARGETARCH.deb" \
		"https://download.docker.com/linux/debian/dists/trixie/pool/stable/$TARGETARCH/docker-ce-cli_28.4.0-1~debian.13~trixie_$TARGETARCH.deb" \
		"https://download.docker.com/linux/debian/dists/trixie/pool/stable/$TARGETARCH/docker-ce_28.4.0-1~debian.13~trixie_$TARGETARCH.deb" \
		"https://download.docker.com/linux/debian/dists/trixie/pool/stable/$TARGETARCH/docker-ce-rootless-extras_28.4.0-1~debian.13~trixie_$TARGETARCH.deb"

##
## Docker Daemon
##

FROM docker.io/library/debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS dockerd
ARG TARGETARCH
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/containerd.io_1.7.28-0~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce_28.4.0-1~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce-cli_28.4.0-1~debian.13~trixie_$TARGETARCH.deb"
COPY --chmod=555 entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

##
## Docker Daemon (rootless)
##

FROM docker.io/library/debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS dockerd-rootless
ARG TARGETARCH
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates uidmap slirp4netns dbus-user-session iproute2 \
		"/tmp/docker/containerd.io_1.7.28-0~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce_28.4.0-1~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce-cli_28.4.0-1~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce-rootless-extras_28.4.0-1~debian.13~trixie_$TARGETARCH.deb"
RUN useradd rootless --uid 1000 --home-dir /home/rootless --create-home && rm -fr /etc/*- && \
	echo rootless:100000:65536 >/etc/subuid && \
	echo rootless:100000:65536 >/etc/subgid && \
	mkdir /run/user -p && chmod 1777 /run/user && \
	mkdir -p /home/rootless/.local/share/docker && \
	chown -R rootless:rootless /home/rootless/.local/share/docker

VOLUME /home/rootless/.local/share/docker
COPY --chmod=555 entrypoint-rootless.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
USER 1000

##
## Docker CLI
##

FROM docker.io/library/debian:13.2-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS cli-base
ARG TARGETARCH
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/docker-buildx-plugin_0.28.0-0~debian.13~trixie_$TARGETARCH.deb" \
		"/tmp/docker/docker-ce-cli_28.4.0-1~debian.13~trixie_$TARGETARCH.deb"
ENV HOME=/woodpecker
RUN mkdir /woodpecker && chown 1000:1000 /woodpecker && chmod 777 /woodpecker

FROM cli-base AS cli-base-az
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends python3 pip
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST
RUN --mount=type=cache,target=/var/cache pip install azure-cli==2.66.0 \
		--root-user-action=ignore \
		--break-system-packages \
		--no-cache-dir

FROM cli-base AS cli
USER 1000:1000

FROM cli-base AS cli-git
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends git
USER 1000:1000

FROM cli-base-az AS cli-az
USER 1000:1000

FROM cli-base-az AS cli-az-git
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends git
USER 1000:1000
