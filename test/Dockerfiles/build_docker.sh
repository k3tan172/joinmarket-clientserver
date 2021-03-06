#!/bin/bash -x

travis_docker_env ()
{
    if [[ -n "${DOCKER_IMG_JM}" ]] && [[ "${HAS_JOSH_K_SEAL_OF_APPROVAL}" == true ]]; then
        return 0
    else
        return 1
    fi
}

build_docker ()
{
    if ! travis_docker_env; then
        return 0
    fi

    core_version='0.17.1'
    core_dist="bitcoin-${core_version}-x86_64-linux-gnu.tar.gz"
    core_url="https://bitcoincore.org/bin/bitcoin-core-${core_version}/${core_dist}"
    libffi_lib_tar='v3.2.1.tar.gz'
    libffi_url="https://github.com/libffi/libffi/archive/${libffi_lib_tar}"
    sodium_lib_tar='libsodium-1.0.13.tar.gz'
    sodium_url="https://download.libsodium.org/libsodium/releases/old/${sodium_lib_tar}"
    declare -A deps=( [${core_dist}]="${core_url}" [${libffi_lib_tar}]="${libffi_url}" [${sodium_lib_tar}]="${sodium_url}" )
    jm_root="${TRAVIS_BUILD_DIR}"
    owner_name="${TRAVIS_REPO_SLUG%\/*}"
    repo_name="${TRAVIS_REPO_SLUG#*\/}"

    for dep in ${!deps[@]}; do
        if [[ ! -r "${HOME}/downloads/${dep}" ]]; then
            curl --retry 5 -L "${deps[${dep}]}" -o "$HOME/downloads/${dep}"
        fi
    done

    mkdir -p "${jm_root}/deps/cache"
    find "$HOME/downloads" -type f -exec cp -v {} "${jm_root}/deps/cache/" \;
    cd "${jm_root}/../"

    docker build \
        --shm-size=1G \
        --build-arg core_version="${core_version}" \
        --build-arg core_dist="${core_dist}" \
        --build-arg repo_name="${repo_name}" \
        -f "./${repo_name}/test/Dockerfiles/${DOCKER_IMG_JM}.Dockerfile" .
    return "$?"
}
build_docker
