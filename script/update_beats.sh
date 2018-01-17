#!/usr/bin/env bash

set -ex

BEATS_VERSION="${BEATS_VERSION:-master}"

# Find basedir and change to it
DIRNAME=$(dirname "$0")
BASEDIR=${DIRNAME}/../_beats
mkdir -p $BASEDIR
pushd $BASEDIR

# Check out beats repo for updating
GIT_CLONE=repo
trap "{ set +e;popd 2>/dev/null;set -e;rm -rf ${BASEDIR}/${GIT_CLONE}; }" EXIT

git clone https://github.com/elastic/beats.git ${GIT_CLONE}
(
    cd ${GIT_CLONE}
    git checkout ${BEATS_VERSION}
)

# sync
rsync -crpv --delete \
    --exclude=.gitignore \
    --exclude=dev-tools/packer/readme.md.j2 \
    --include="script/***" \
    --include="dev-tools/***" \
    --include="libbeat/scripts/***" \
    --include="libbeat/_meta/***" \
    --include=libbeat/Makefile \
    --include="libbeat/processors/*/_meta/***" \
    --include=libbeat/tests/system/requirements.txt \
    --include="libbeat/tests/system/beat/***" \
    --include=libbeat/docs/version.asciidoc \
    --include=.go-version \
    --include="testing/***" \
    --exclude="*" \
    ${GIT_CLONE}/ .

popd

# use exactly the same beats revision rather than $BEATS_VERSION
BEATS_REVISION=$(GIT_DIR=${BASEDIR}/${GIT_CLONE}/.git git rev-parse HEAD)
${DIRNAME}/update_govendor_deps.py ${BEATS_REVISION}
