#!/usr/bin/env bash
set -e


# -- config
REPO=https://github.com/cfallin/wasmtime
BENCHES="regex-rs bz2"
# --

if [ $# -lt 1 ]; then
  echo "Usage: run.sh HASH"
  exit 1
fi

ROOT=`dirname $0`
ROOT=`readlink -f $ROOT`
BINS=$ROOT/binaries
mkdir -p $BINS
HASH=$1
WTBIN=$BINS/wasmtime.$HASH
CLBIN=$BINS/clif-util.$HASH
OUT=$ROOT/data/out.$HASH
mkdir -p $OUT
OUT=`readlink -f $OUT`

need_run() {
  for bench in $BENCHES; do
    if [ ! -f $OUT/complete.$bench ]; then
      echo 1
      return
    fi
  done
  echo 0
}

ensure_binaries() {
  if [ ! -x $WTBIN ] || [ ! -x $CLBIN ]; then
    DIR=`mktemp -d`
    pushd $DIR
    git init wasmtime
    cd wasmtime/
    git fetch --depth 1 $REPO $HASH:eval
    git checkout eval
    git submodule update --init --depth 1

    echo "Checked out in `pwd`..."

    cargo build -p cranelift-tools --release && cargo build --release
    cp target/release/clif-util $CLBIN
    cp target/release/wasmtime $WTBIN
    popd
    rm -rf $DIR
  fi
}

get_icount() {
  OUT=$1
  shift
  valgrind --tool=cachegrind --cache-sim=no --cachegrind-out-file=$OUT "$@"
}

do_runs() {
  export RAYON_NUM_THREADS=1

  for bench in $BENCHES; do
    if [ -f $OUT/complete.$bench ]; then
      continue
    fi
    rm -f $OUT/compile.$bench.*
    rm -f $OUT/compile-run.$bench.*

    FAIL=0

    for i in `seq 0 9`; do
      echo "Run $i: $bench: compile time"
      rm -f $OUT/compile.$bench.$i.cachegrind
      get_icount $OUT/compile.$bench.$i.cachegrind \
           $CLBIN wasm --set opt_level=speed --set enable_verifier=false --target aarch64 \
           $ROOT/$bench.wasm || FAIL=1
    done

    for i in `seq 0 9`; do
      echo "Run $i: $bench: compile time + runtime "
      rm -f $OUT/compile-run.$bench.$i.cachegrind
      get_icount $OUT/compile-run.$bench.$i.cachegrind \
           $WTBIN run --disable-cache $ROOT/$bench.wasm || FAIL=1
    done

    if [ $FAIL -eq 0 ]; then
      touch $OUT/complete.$bench
    fi
  done

  echo "Results in $OUT"
}

main() {
  if ! need_run; then
    exit 0
  fi

  ensure_binaries
  do_runs
}

main


