# hadolint global ignore=DL3008

##
## Download docker
##

FROM docker.io/library/debian:12.11-slim@sha256:e5865e6858dacc255bead044a7f2d0ad8c362433cfaa5acefb670c1edf54dfef AS download
WORKDIR /tmp/docker
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates curl && \
	rm -rf /etc/*- /var/lib/dpkg/*-old /var/lib/dpkg/status
RUN ARCH=$(dpkg --print-architecture) && curl --fail --silent --parallel --remote-name-all \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/containerd.io_1.7.27-1_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-buildx-plugin_0.24.0-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce-cli_28.2.2-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce_28.2.2-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce-rootless-extras_28.2.2-1~debian.12~bookworm_$ARCH.deb"

##
## Docker Daemon
##

FROM docker.io/library/debian:12.11-slim@sha256:e5865e6858dacc255bead044a7f2d0ad8c362433cfaa5acefb670c1edf54dfef AS dockerd
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/containerd.io_1.7.27-1_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" && \
	rm -rf /var/lib/dpkg/*-old /var/lib/dpkg/status
COPY --chmod=555 entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

##
## Docker Daemon (rootless)
##

FROM docker.io/library/debian:12.11-slim@sha256:e5865e6858dacc255bead044a7f2d0ad8c362433cfaa5acefb670c1edf54dfef AS dockerd-rootless
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates uidmap slirp4netns dbus-user-session iproute2 fuse-overlayfs \
		"/tmp/docker/containerd.io_1.7.27-1_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-rootless-extras_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" && \
	rm -rf /var/lib/dpkg/*-old /var/lib/dpkg/status
RUN useradd dockerd --uid 1000 --home-dir /home/docker --create-home && rm -fr /etc/*- && \
	echo dockerd:100000:65536 >/etc/subuid && \
	echo dockerd:100000:65536 >/etc/subgid
COPY --chmod=555 entrypoint-rootless.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
ENV HOME=/home/docker
USER 1000

##
## Docker CLI
##

FROM docker.io/library/debian:12.11-slim@sha256:e5865e6858dacc255bead044a7f2d0ad8c362433cfaa5acefb670c1edf54dfef AS cli-base
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/docker-buildx-plugin_0.24.0-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" && \
	rm -rf /etc/*- /var/lib/dpkg/*-old /var/lib/dpkg/status
ENV DOCKER_HOST=tcp://dockerd:2375
ENV HOME=/woodpecker

FROM cli-base AS cli-base-az
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends python3 pip && \
	rm -rf /etc/*- /var/lib/dpkg/*-old /var/lib/dpkg/status
ARG PYPI_MIRROR=https://mirror.kokuwa.io/pypi/simple/
# pip cache is explicit stored in cache mount
# hadolint ignore=DL3042
RUN --mount=type=cache,target=/var/cache pip install azure-cli==2.66.0 \
		--root-user-action=ignore \
		--break-system-packages \
		--cache-dir=/var/cache/.cache/pip \
		--index-url=$PYPI_MIRROR

FROM cli-base AS cli
USER 1000:1000

FROM cli-base AS cli-git
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends git && \
	rm -rf /var/lib/dpkg/*-old /var/lib/dpkg/status
USER 1000:1000

FROM cli-base-az AS cli-az
USER 1000:1000

FROM cli-base-az AS cli-az-git
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends git && \
	rm -rf /var/lib/dpkg/*-old /var/lib/dpkg/status
USER 1000:1000
