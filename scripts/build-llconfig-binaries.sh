#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/home/dot_local/libexec/llconfig"
LLCONFIG_REV="bdffdcd14e6c5fb8c0b014ee8a7df897fafcb8e2"
LLCONFIG_REPO="https://github.com/landlock-lsm/landlockconfig.git"

# Build one static target in a digest-pinned musl cross-compiler image.
build_binary() {
  image="$1"
  output_name="$2"

  docker run --rm \
    --env "HOST_GID=$(id -g)" \
    --env "HOST_UID=$(id -u)" \
    --env "LLCONFIG_REPO=$LLCONFIG_REPO" \
    --env "LLCONFIG_REV=$LLCONFIG_REV" \
    --env "OUTPUT_NAME=$output_name" \
    --volume "$OUTPUT_DIR:/out" \
    "$image" \
    sh -euc '
      workdir="$(mktemp -d)"
      trap '\''rm -rf "$workdir"'\'' EXIT INT TERM

      git clone --quiet "$LLCONFIG_REPO" "$workdir"
      git -C "$workdir" checkout --quiet --detach "$LLCONFIG_REV"
      cargo build --locked --release --package llconfig --manifest-path "$workdir/Cargo.toml"

      binary="$workdir/target/$CARGO_BUILD_TARGET/release/llconfig"
      "/usr/local/musl/bin/$CARGO_BUILD_TARGET-strip" "$binary"
      install -m 0755 "$binary" "/out/$OUTPUT_NAME"
      chown "$HOST_UID:$HOST_GID" "/out/$OUTPUT_NAME"
    '
}

mkdir -p "$OUTPUT_DIR"

build_binary \
  "messense/rust-musl-cross:x86_64-musl@sha256:ce75e9174325d4fbb3de85c309e2d7ca29f7500169bc4b5d2c611ff7e86d549a" \
  "executable_llconfig-linux-amd64"
build_binary \
  "messense/rust-musl-cross:aarch64-musl@sha256:ecae5dd62d1c938c14f8071d36c16fa699860aace03bfb5284fb1216474d2643" \
  "executable_llconfig-linux-arm64"
