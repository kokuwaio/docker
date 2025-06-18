#!/bin/bash
set -e;

# https://docs.docker.com/reference/cli/dockerd/

##
## build command to execute
##

COMMAND="dockerd --host=0.0.0.0:${DOCKERD_PORT:-2375} --tls=false --data-root=/woodpecker/dockerd --feature=buildkit=true --feature=containerd-snapshotter=true --shutdown-timeout=${DOCKERD_SHUTDOWN_TIMEOUT:-0} "
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

echo
echo Running now:
echo
echo -e "  ${COMMAND// --/ \\n    --}"
echo
eval "$COMMAND"
