#!/bin/bash
# Starts Julia with the given arguments. If the environment variable PLUTO_STARTUP_DIAG is set
# (in the question's info.json), first show a status page on port 1234 with timings of the
# startup stages, to find out why a workspace is slow to start.
if [ -z "$PLUTO_STARTUP_DIAG" ]; then
    exec julia "$@"
fi

export PLUTO_STARTUP_LOG=/tmp/startup_timing.log
rm -f /tmp/stop_responder /tmp/responder_closed
stamp() { echo "$(date +%H:%M:%S) $*" >> "$PLUTO_STARTUP_LOG"; }
since() { awk "BEGIN{printf \"%.1f s\", $(date +%s.%N) - $1}"; }

stamp "start.sh: container started"
julia --startup-file=no /home/julia/project/responder.jl &
stamp "start.sh: status page launched"
stamp "info: $(nproc) CPUs visible; cgroup cpu.max=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null); memory.max=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)"
stamp "info: cpu model:$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2); flags avx2/avx512: $(grep -c -m1 avx2 /proc/cpuinfo)/$(grep -c -m1 avx512f /proc/cpuinfo)"
stamp "info: $(julia --version); depot size: $(du -sh /home/julia/.julia 2>/dev/null | cut -f1)"

t=$(date +%s.%N); julia --startup-file=no -e '1+1'; stamp "test: bare julia process took $(since $t)"
t=$(date +%s.%N); n=$(tar cf - /home/julia/.julia/compiled /home/julia/server 2>/dev/null | wc -c); stamp "test: reading the compiled package cache ($((n / 1048576)) MB) took $(since $t)"
t=$(date +%s.%N); julia --startup-file=no --project=/home/julia/server -e 'using Pluto' 2>&1 | tail -3 >> "$PLUTO_STARTUP_LOG"; stamp "test: 'using Pluto' in a separate process took $(since $t)"

stamp "start.sh: starting the real server"
exec julia "$@"
