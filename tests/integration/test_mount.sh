#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

#
# 'atomic mount' integration tests
# AUTHOR: William Temple <wtemple at redhat dot com>
#

if [[ "$(id -u)" -ne "0" ]]; then
    echo "Atomic mount tests require root access to manipulate devices."
    exit 1
fi

setup () {
    MNT_WORK="${WORK_DIR}/mnt_work"
    mkdir -p "${MNT_WORK}"
    mkdir -p "${MNT_WORK}/container"
    mkdir -p "${MNT_WORK}/image"

    INAME="atomic-test-secret"
}

teardown () {
    rm -rf "${MNT_WORK}"
}
trap teardown EXIT

setup

id=`${DOCKER} create ${INAME} /bin/true`

cleanup_container () {
    ${DOCKER} rm ${id}
    teardown
}
trap cleanup_container EXIT

${ATOMIC} mount ${id} ${MNT_WORK}/container
${ATOMIC} mount ${INAME} ${MNT_WORK}/image

cleanup_mount () {
    ${ATOMIC} unmount ${MNT_WORK}/container
    ${ATOMIC} unmount ${MNT_WORK}/image
    cleanup_container
}
trap cleanup_mount EXIT

# Expect failure
set +e
${ATOMIC} mount ${id} --live ${MNT_WORK}/container
if [ "$?" -eq "0" ]; then
    exit 1
fi
${ATOMIC} mount ${INAME} --live ${MNT_WORK}/image
if [ "$?" -eq "0" ]; then
    exit 1
fi

set -e

${ATOMIC} unmount ${MNT_WORK}/container
${ATOMIC} mount ${id} --shared ${MNT_WORK}/container

if [[ "`cat "${MNT_WORK}/container/secret"`" !=  "${SECRET}" ]]; then
    exit 1
fi
if [[ "`cat "${MNT_WORK}/image/secret"`" != "${SECRET}" ]]; then
    exit 1
fi

running_cont=$(${DOCKER} run -d centos sleep infinity)

cleanup_working_cont () {
    cleanup_mount
    ${DOCKER} rm -f ${running_cont}
}
trap cleanup_working_cont EXIT

${ATOMIC} unmount ${MNT_WORK}/container
${ATOMIC} mount ${running_cont} --live ${MNT_WORK}/container

touch ${MNT_WORK}/container/we_can_write_here
${DOCKER} cp ${running_cont}:/we_can_write_here ${MNT_WORK}/
