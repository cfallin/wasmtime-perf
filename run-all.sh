#!/bin/bash

for commit in `cat commits.txt | awk '{print $1}'`; do
  echo "COMMIT: $commit"
  ./run.sh $commit
done
