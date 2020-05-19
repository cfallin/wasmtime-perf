#!/usr/bin/env bash
set -e


# -- config
REPO=https://github.com/bytecodealliance/wasmtime
BENCHES="bz2"
# --

if [ $# -lt 2 ]; then
  echo "Usage: run.sh HASH OUTDIR"
fi

ROOT=`dirname $0`
HASH=$1
OUT=$2
DIR=`mktemp -d`

OUT=`readlink -f $OUT`

cd $DIR
git init wasmtime
cd wasmtime/
git fetch --depth 1 $REPO $HASH:eval
git checkout eval
git submodule update --init --depth 1

echo "Checked out in `pwd`..."

cargo build -p cranelift-tools --release

for bench in $BENCHES; do
  for i in `seq 0 9`; do
    perf stat target/release/clif-util wasm --set opt_level=speed --set enable_verifier=false --target aarch64 $ROOT/$bench.wasm 2>$OUT/compile.$bench.$i.txt
  done

  for i in `seq 0 9`; do
    perf stat target/release/wasmtime run --disable-cache $ROOT/$bench.wasm 2>$OUT/compile.$bench.$i.txt
  done
done

echo "Results in $OUT"
