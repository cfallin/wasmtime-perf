#!/bin/bash

BENCHES="regex-rs bz2"
FILTER=$1
if [ "x$FILTER" = "x" ]; then
  FILTER=""
fi

get_stat() {
  file=$1
  stat=$2
  if [ ! -f $file ]; then
    echo "FAIL"
    return
  fi
  if ! grep -q $stat $file; then
    echo "FAIL"
    return
  fi
  grep $stat $file | awk '{print $1}' | sed -e 's/,//g'
}

echo "Commit,Bench,Run,Cycles (compile),Cycles (comp+run),Instructions (compile),Instructions (comp+run),Wallclock (compile),Wallclock (comp+run)"
for dir in data/out.${FILTER}*; do
  h=`basename $dir`
  h=`echo $h | sed -e 's/out.//'`
  for bench in $BENCHES; do
    for i in `seq 0 9`; do
      C=$dir/compile.$bench.$i.txt
      R=$dir/compile-run.$bench.$i.txt

      C_cyc=`get_stat $C cycles`
      C_inst=`get_stat $C instructions`
      C_wall=`get_stat $C task-clock`
      R_cyc=`get_stat $R cycles`
      R_inst=`get_stat $R instructions`
      R_wall=`get_stat $R task-clock`
      echo "$h,$bench,$i,${C_cyc},${R_cyc},${C_inst},${R_inst},${C_wall},${R_wall}"
    done
  done
done
