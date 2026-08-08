import sys

def parse2(s):
    d = {}
    for item in s.split():
        parts = item.split(':')
        if len(parts) == 3:
            d[int(parts[0])] = (int(parts[1]), int(parts[2]))
    return d

prev_str = sys.argv[1].strip() if len(sys.argv) > 1 else ""
cur_str = sys.argv[2].strip() if len(sys.argv) > 2 else ""

prev = parse2(prev_str)
cur = parse2(cur_str)

if not prev or not cur:
    sys.exit(0)

core_ids = []
with open('/proc/cpuinfo') as f:
    for line in f:
        if line.startswith('core id'):
            cid = int(line.split(':')[1].strip())
            if cid not in core_ids:
                core_ids.append(cid)

thread_usage = {}
for t in sorted(set(prev.keys()) & set(cur.keys())):
    dt = cur[t][0] - prev[t][0]
    di = cur[t][1] - prev[t][1]
    if dt > 0:
        thread_usage[t] = (1 - di/dt) * 100

thread_to_core = {}
for t in range(len(core_ids) * 2):
    idx = t // 2
    if idx < len(core_ids):
        thread_to_core[t] = core_ids[idx]

core_sum = {}
core_cnt = {}
for t, usage in thread_usage.items():
    c = thread_to_core.get(t, t)
    core_sum[c] = core_sum.get(c, 0) + usage
    core_cnt[c] = core_cnt.get(c, 0) + 1

result = []
for c in core_ids:
    if c in core_cnt and core_cnt[c] > 0:
        result.append(f"{core_sum[c]/core_cnt[c]:.1f}")
print(",".join(result))
