#!/bin/bash
# build and pack a rust lambda library
# https://aws.amazon.com/blogs/opensource/rust-runtime-for-aws-lambda/

set -eo pipefail
mkdir -p target/lambda
export PROFILE=${PROFILE:-release}
# cargo uses different names for target
# of its build profiles
if [[ "${PROFILE}" == "release" ]]; then
    profile_opt="--release"
    TARGET_PROFILE="${PROFILE}"
else
    TARGET_PROFILE="debug"
fi
export CARGO_TARGET_DIR=$PWD/target/lambda

cargo build "$@" $profile_opt

function package() {
    file="$1"
    strip "$file"
    rm "$file.zip" > 2&>/dev/null || true
    # note: would use printf "@ $(basename $file)\n@=bootstrap" | zipnote -w "$file.zip"
    # if not for https://bugs.launchpad.net/ubuntu/+source/zip/+bug/519611
    if [ "$file" != ./bootstrap ] && [ "$file" != bootstrap ]; then
        mv "${file}" bootstrap
    fi
    zip "$file.zip" bootstrap
    rm bootstrap
}

cd "${CARGO_TARGET_DIR}/${TARGET_PROFILE}"

if [ -z "$BIN" ]; then
    IFS=$'\n'
    for executable in $(cargo read-manifest | jq -r '.targets[] | select(.kind[] | contains("bin")) | .name'); do
        package "$executable"
    done
else
    package "$BIN"
fi
