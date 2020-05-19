#!/usr/bin/env python3

import sys
import os

class Avg(object):
    def __init__(self):
        self.samples = []
    def add(self, value):
        self.samples.append(value)
    def mean(self):
        if len(self.samples) == 0:
            return 0.0
        else:
            return float(sum(self.samples)) / len(self.samples)

class Avgs(object):
    def __init__(self, columns):
        self.columns = columns
        self.avgs = [Avg() for c in columns]
    def add_line(self, parts):
        if len(parts) != len(self.avgs):
            self.avgs = [None for c in self.columns]

        for i in range(len(parts)):
            if parts[i].strip() == 'FAIL':
                self.avgs[i] = None
            else:
                self.avgs[i].add(float(parts[i]))

    def report(self):
        avgs = map(lambda a: 'FAIL' if a is None else str(a.mean()), self.avgs)
        return dict(zip(self.columns, avgs))

    def reset(self):
        self.avgs = [Avg() for c in self.columns]


# returns [{bench,
#           compile_instructions, compile_cycles, compile_wallclock,
#           comprun_instructions, comprun_cycles, comprun_wallclock}]
def get_data(commithash):
    with os.popen("./parse.sh %s" % commithash) as of:
        ret = []
        last_bench = None
        avgs = Avgs(['compile_cycles', 'comprun_cycles', 'compile_instructions', 'comprun_instructions', 'compile_wallclock', 'comprun_wallclock'])
        for line in of.readlines()[1:]:
            parts = line.split(',')
            if len(parts) < 9:
                print("fail for %s: %s" % (commithash, line))
                failed = True
                continue
            if parts[0] != commithash:
                print("fail for %s: %s" % (commithash, line))
                failed = True
                continue

            bench = parts[1]
            num = parts[2]

            if bench != last_bench:
                if last_bench != None:
                    rep = avgs.report()
                    rep['bench'] = last_bench
                    ret.append(rep)
                avgs.reset()
            last_bench = bench

            avgs.add_line(parts[3:])

        if last_bench != None:
            rep = avgs.report()
            rep['bench'] = last_bench
            ret.append(rep)

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

    print("Commit,Description,Bench,Inst (Comp),Inst (Comp+Run),Cyc (Comp),Cyc (Comp+Run), Wallclock (Comp), Wallclock (Comp+Run)")
    for commit in commits:
        data = get_data(commit['commithash'])
        for row in data:
            print('%s,"%s",%s,%s,%s,%s,%s,%s,%s' %
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
