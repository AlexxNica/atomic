#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

EXPECTED_T1="Checksum: $(sha256sum ./tests/test-images/Dockerfile.1)"

validTest1 () {
    for e in ${TEST_1}; do
        [[ $e = ${EXPECTED_T1}* ]] && return 0;
    done
    return 1
}

TEST_1=`${ATOMIC} info atomic-test-1`
TEST_CENTOS_REMOTE=`${ATOMIC} info --remote centos:latest`
TEST_CENTOS=`${ATOMIC} info centos:latest`

set +e

TEST_DOES_NOT_EXIST=`${ATOMIC} info this-is-not-a-real-image`

set -e

echo $TEST_1

if [[ "${TEST_CENTOS_REMOTE}" != "${TEST_CENTOS}" ]]; then
    exit 1
fi

if [[ "${TEST_DOES_NOT_EXIST}" != "" ]]; then
    exit 1
fi

validTest1

if [[ $? -ne 0 ]]; then
    exit 1
fi
