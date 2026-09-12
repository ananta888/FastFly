#!/bin/bash
# Wait for the NVIDIA GPU to actually be usable before starting the
# simulator. On a fresh boot, nvidia-persistenced/the driver can take a
# couple of minutes to become ready; without this, fastfly-server crash-loops
# dozens of times against cudaErrorNoDevice/cudaErrorUnknown until it settles
# (observed: 32 failed attempts over ~3 minutes on 2026-09-12).
#
# `nvidia-smi -L` is used as the readiness probe rather than just checking
# that nvidia-persistenced.service is active, since that only tells us the
# daemon process started -- not that the driver will actually hand out a
# working CUDA context yet.

MAX_WAIT_SECS=180
INTERVAL_SECS=2
elapsed=0

while [ "$elapsed" -lt "$MAX_WAIT_SECS" ]; do
    if nvidia-smi -L >/dev/null 2>&1; then
        echo "wait-for-gpu.sh: GPU ready after ${elapsed}s"
        exit 0
    fi
    sleep "$INTERVAL_SECS"
    elapsed=$((elapsed + INTERVAL_SECS))
done

echo "wait-for-gpu.sh: GPU still not ready after ${MAX_WAIT_SECS}s, starting anyway" >&2
exit 0
