#!/usr/bin/env bash
set -e
this_dir="$( cd "$( dirname "$0" )" && pwd )"

if [[ -z "$(command -v qemu-arm-static)" ]]; then
    echo "Need to install qemu-user-static"
    sudo apt-get update
    sudo apt-get install qemu-arm-static
fi

# Copy qemu for ARM architectures
mkdir -p "${this_dir}/etc"
for qemu_file in qemu-arm-static qemu-aarch64-static; do
    dest_file="${this_dir}/etc/${qemu_file}"

    if [[ ! -s "${dest_file}" ]]; then
        cp "$(which ${qemu_file})" "${dest_file}"
    fi
done

# Do Docker builds
docker_archs=('amd64' 'arm32v7' 'arm64v8' 'arm32v6')
if [[ ! -z "$1" ]]; then
    docker_archs=("$@")
fi
declare -A friendly_archs
friendly_archs=(['amd64']='amd64' ['arm32v7']='armhf' ['arm64v8']='aarch64' ['arm32v6']='arm32v6')

for docker_arch in "${docker_archs[@]}"; do
    friendly_arch="${friendly_archs[${docker_arch}]}"
    echo "${docker_arch} ${friendly_arch}"

    if [[ -z "${friendly_arch}" ]]; then
       exit 1
    fi

    mkdir -p "${this_dir}/dist"
    docker_tag="rhasspy/mitlm:0.4.2-${friendly_arch}"

    if [[ "${friendly_arch}" == 'arm32v6' ]]; then
        docker build "${this_dir}" \
               --build-arg "BUILD_FROM=balenalib/raspberry-pi-debian:buster-build" \
               -t "${docker_tag}"
    else
        docker build "${this_dir}" \
               --build-arg "BUILD_FROM=${docker_arch}/debian:stretch" \
               -t "${docker_tag}"
    fi

    # Copy out build artifacts
    docker run -it \
           -v "${this_dir}/dist:/dist" \
           -u "$(id -u):$(id -g)" \
           "${docker_tag}" \
           /bin/tar -czvf "/dist/mitlm-0.4.2-${friendly_arch}.tar.gz" /mitlm

    # Alpine build
    docker_tag="rhasspy/mitlm:0.4.2-${friendly_arch}-alpine"

    docker build "${this_dir}" \
           -f Dockerfile.alpine \
           --build-arg "BUILD_FROM=${docker_arch}/alpine:3.9" \
           -t "${docker_tag}"

    # Copy out build artifacts
    docker run -it \
           -v "${this_dir}/dist:/dist" \
           -u "$(id -u):$(id -g)" \
           "${docker_tag}" \
           /bin/tar -czvf "/dist/mitlm-0.4.2-${friendly_arch}-alpine.tar.gz" /mitlm
done
