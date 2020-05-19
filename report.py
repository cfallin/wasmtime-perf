#!/usr/bin/env python3

import sys
import os

# returns [{bench, commithash,
#           compile_instructions, compile_cycles, compile_wallclock,
#           comprun_instructions, comprun_cycles, comprun_wallclock}]
def get_data(commithash):
    with os.popen("./parse.sh %s" % commithash) as of:
        ret = []
        last_bench = None
        count = 0
        comp_cyc_total = 0.0
        comprun_cyc_total = 0.0
        comp_ins_total = 0.0
        comprun_ins_total = 0.0
        comp_wall_total = 0.0
        comprun_wall_total = 0.0
        failed = False
        for line in of.readlines():
            parts = line.split(',')
            if len(parts) < 9:
                failed = True
                continue

            if parts[0] != commithash:
                failed = True
                continue

            bench = parts[1]
            num = parts[2]

            if num == 0:
                failed = False
            if any(map(lambda val: val == 'FAIL', parts)):
                failed = True
                continue

            comp_cyc_total += float(parts[3])
            comprun_cyc_total += float(parts[4])
            comp_ins_total += float(parts[5])
            comprun_ins_total += float(parts[6])
            comp_wall_total += float(parts[7])
            comprun_wall_total += float(parts[8])
            if not failed and num == 9:
                ret.append({                                       \
                    'bench': bench,                                \
                    'commithash': commithash,                      \
                    'compile_instructions': comp_ins / 10.0,       \
                    'comprun_instructions': comprun_ins / 10.0,    \
                    'compile_cycles': comp_cyc / 10.0,             \
                    'comprun_cycles': comprun_cyc / 10.0,          \
                    'compile_wallclock': comp_wallclock / 10.0,    \
                    'comprun_wallclock': comprun_wallclock / 10.0, \
                })
        return ret

# returns [{commithash, desc}]
def get_commitlist():
    with open('commits.txt') as of:
        ret = []
        for line in of.readlines():
            parts = line.split(' ', 1)
            ret.append({                \
                'commithash': parts[0], \
                'desc': parts[1],       \
            })
        return ret

def report():
    commits = get_commitlist()

    print("Commit,Description,Bench,Inst (Comp),Inst (Comp+Run),Cyc (Comp),Cyc (Comp+Run), Wallclock (Comp), Wallclock (Comp+Run)")
    for commit in commits:
        data = get_data(commit['commithash'])
        for row in data:
            print('%s,"%s",%s,%f,%f,%f,%f,%f,%f' %
                    (commit['commithash'],
                     commit['desc'],
                     row['bench'],
                     row['compile_instructions'],
                     row['comprun_instructions'],
                     row['compile_cycles'],
                     row['comprun_cycles'],
                     row['compile_wallclock'],
                     row['comprun_wallclock']))

report()
