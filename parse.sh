#!/bin/bash

BENCHES="regex-rs bz2"
FILTER=$1
if [ "x$FILTER" = "x" ]; then
  FILTER=""
fi

echo "Commit,Bench,Instructions (compile)"
for dir in data/out.${FILTER}*; do
  h=`basename $dir`
  h=`echo $h | sed -e 's/out.//'`
  for bench in $BENCHES; do
    file=$dir/compile.$bench.0.cachegrind
    C_cyc=`cg_annotate $file | grep 'PROGRAM TOTALS' | awk '{print $1}' | sed -e 's/,//g'`
    echo "${h},${bench},${C_cyc}"
  done
done
