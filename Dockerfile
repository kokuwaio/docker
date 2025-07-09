# hadolint global ignore=DL3008

##
## Download docker
##

FROM docker.io/library/debian:12.11-slim@sha256:6ac2c08566499cc2415926653cf2ed7c3aedac445675a013cc09469c9e118fdd AS download
WORKDIR /tmp/docker
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates curl 
RUN ARCH=$(dpkg --print-architecture) && curl --fail --silent --parallel --remote-name-all \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/containerd.io_1.7.27-1_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-buildx-plugin_0.24.0-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce-cli_28.2.2-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce_28.2.2-1~debian.12~bookworm_$ARCH.deb" \
		"https://download.docker.com/linux/debian/dists/bookworm/pool/stable/$ARCH/docker-ce-rootless-extras_28.2.2-1~debian.12~bookworm_$ARCH.deb"

##
## Docker Daemon
##

FROM docker.io/library/debian:12.11-slim@sha256:6ac2c08566499cc2415926653cf2ed7c3aedac445675a013cc09469c9e118fdd AS dockerd
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/containerd.io_1.7.27-1_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb"
COPY --chmod=555 entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

##
## Docker Daemon (rootless)
##

FROM docker.io/library/debian:12.11-slim@sha256:6ac2c08566499cc2415926653cf2ed7c3aedac445675a013cc09469c9e118fdd AS dockerd-rootless
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates uidmap slirp4netns dbus-user-session iproute2 \
		"/tmp/docker/containerd.io_1.7.27-1_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-rootless-extras_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb"
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

FROM docker.io/library/debian:12.11-slim@sha256:6ac2c08566499cc2415926653cf2ed7c3aedac445675a013cc09469c9e118fdd AS cli-base
RUN --mount=type=bind,from=download,source=/tmp/docker,target=/tmp/docker \
	--mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
	--mount=type=cache,target=/var/cache \
	--mount=type=tmpfs,target=/var/lib/dpkg \
	--mount=type=tmpfs,target=/var/log \
	apt-get -qq update && \
	apt-get -qq install --yes --no-install-recommends ca-certificates \
		"/tmp/docker/docker-buildx-plugin_0.24.0-1~debian.12~bookworm_$(dpkg --print-architecture).deb" \
		"/tmp/docker/docker-ce-cli_28.2.2-1~debian.12~bookworm_$(dpkg --print-architecture).deb"
ENV DOCKER_HOST=tcp://dockerd:2375
ENV HOME=/woodpecker

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
