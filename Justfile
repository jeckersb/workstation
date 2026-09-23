version := "44"

build *args:
	podman pull quay.io/fedora/fedora-bootc:{{version}}
	podman build {{args}} --build-arg FEDORA_VERSION={{version}} -t localhost/workstation:unchunked .

chunk: build
	#!/bin/bash
	set -xeuo pipefail
	CHUNKAH_CONFIG_STR="$(podman inspect localhost/workstation:unchunked)"
	buildah build --skip-unused-stages=false --from localhost/workstation:unchunked \
	  --build-arg CHUNKAH_CONFIG_STR="$CHUNKAH_CONFIG_STR" \
	  --build-arg CHUNKAH_ARGS="--prune /sysroot/ --max-layers 128" \
	  -t localhost/workstation:latest \
	  -v $(pwd):/run/src --security-opt=label=disable \
	  https://github.com/coreos/chunkah/releases/download/v0.6.0/Containerfile.splitter
