#!/bin/bash
set -e;

# https://docs.docker.com/reference/cli/dockerd/

##
## build command to execute
##

COMMAND="dockerd --rootless --host=0.0.0.0:${DOCKERD_PORT:-2375} --tls=false --data-root=/home/docker --storage-driver=fuse-overlayfs --shutdown-timeout=${DOCKERD_SHUTDOWN_TIMEOUT:-0} --feature=buildkit=true --feature=containerd-snapshotter=true"
if [[ -n "$DOCKERD_LOG_LEVEL" ]]; then
	COMMAND+=" --log-level=$DOCKERD_LOG_LEVEL"
fi
if [[ -n "$DOCKERD_REGISTRY_MIRROR" ]]; then
	COMMAND+=" --registry-mirror=$DOCKERD_REGISTRY_MIRROR"
	if [[ "$DOCKERD_REGISTRY_MIRROR" =~ ^http:\/\/.*$ ]]; then
		COMMAND+=" --insecure-registry=${DOCKERD_REGISTRY_MIRROR//http:\/\//}"
	fi
fi
if [[ -n "$DOCKERD_INSECURE_REGISTRY" ]]; then
	COMMAND+=" --insecure-registry=$DOCKERD_INSECURE_REGISTRY"
fi

##
## execute command
##

export XDG_RUNTIME_DIR=/home/docker/runtime
COMMAND="rootlesskit --publish=0.0.0.0:${DOCKERD_PORT:-2375}:${DOCKERD_PORT:-2375}/tcp --disable-host-loopback --copy-up=/etc --copy-up=/run --net=slirp4netns --slirp4netns-sandbox=auto --slirp4netns-seccomp=auto --port-driver=builtin $COMMAND"

echo
echo Running now:
echo
echo -e "  ${COMMAND// --/ \\n    --}"
echo
eval "$COMMAND"
