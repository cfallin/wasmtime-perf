#!/usr/bin/env python3

import sys
import os

# returns [{bench, compile_instructions}]
def get_data(commithash):
    with os.popen("./parse.sh %s" % commithash) as of:
        ret = []
        for line in of.readlines()[1:]:
            parts = line.split(',')
            if len(parts) < 3:
                print("fail for %s: %s" % (commithash, line))
                failed = True
                continue
            if parts[0] != commithash:
                print("fail for %s: %s" % (commithash, line))
                failed = True
                continue

            bench = parts[1]
            insts = int(parts[2])
            ret.append({ 'bench': bench, 'compile_instructions': insts})

        return ret

# returns [{commithash, desc}]
def get_commitlist():
    with open('commits.txt') as of:
        ret = []
        for line in of.readlines():
            parts = line.split(' ', 1)
            ret.append({                        \
                'commithash': parts[0].strip(), \
                'desc': parts[1].strip(),       \
            })
        return ret

def report():
    commits = get_commitlist()

    print("Commit,Description,Bench,Inst (Comp)")
    for commit in commits:
        data = get_data(commit['commithash'])
        for row in data:
            print('%s,"%s",%s,%d' % \
                    (commit['commithash'],
                     commit['desc'],
                     row['bench'],
                     row['compile_instructions']))

report()
