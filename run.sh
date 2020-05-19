#!/usr/bin/env bash
set -e


# -- config
REPO=https://github.com/bytecodealliance/wasmtime
BENCHES="regex-rs bz2"
# --

if [ $# -lt 1 ]; then
  echo "Usage: run.sh HASH"
fi

ROOT=`dirname $0`
ROOT=`readlink -f $ROOT`
HASH=$1
OUT=$ROOT/data/out.$HASH
DIR=`mktemp -d`

OUT=`readlink -f $OUT`
mkdir -p $OUT

cd $DIR
git init wasmtime
cd wasmtime/
git fetch --depth 1 $REPO $HASH:eval
git checkout eval
git submodule update --init --depth 1

echo "Checked out in `pwd`..."

cargo build -p cranelift-tools --release && cargo build --release

export RAYON_NUM_THREADS=1

for bench in $BENCHES; do
  if [ -f $OUT/complete.$bench ]; then
    continue
  fi
  rm -f $OUT/compile.$bench.*
  rm -f $OUT/compile-run.$bench.*

  for i in `seq 0 9`; do
    echo "Run $i: $bench: compile time"
    if ! perf stat \
         target/release/clif-util wasm --set opt_level=speed --set enable_verifier=false --target aarch64 \
         $ROOT/$bench.wasm 2>$OUT/compile.$bench.$i.txt; then
      rm $OUT/compile.$bench.$i.txt
    fi
  done

  for i in `seq 0 9`; do
    echo "Run $i: $bench: compile time + runtime "
    if ! perf stat \
         target/release/wasmtime run --disable-cache \
         $ROOT/$bench.wasm 2>$OUT/compile-run.$bench.$i.txt; then
      rm $OUT/compile-run.$bench.$i.txt
    fi
  done

  touch $OUT/complete.$bench
done

echo "Results in $OUT"

rm -rf $DIR
