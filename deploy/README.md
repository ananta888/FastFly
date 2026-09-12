# Deployment

`fastfly-server.service` here is a reference copy of the live unit at
`~/.config/systemd/user/fastfly-server.service` on the deployment host — that
one is what systemd actually reads; this copy exists only so the config is
version-controlled. After editing the live one, re-copy it here (or vice
versa) and run `systemctl --user daemon-reload`.

## GPU-readiness crash loop (fixed 2026-09-12)

On every boot, `nvidia-persistenced` can take a couple of minutes to bring the
driver up. The service unit only had `After=network.target`, so systemd
started `app_server.py` immediately — it crashed against
`cudaErrorNoDevice`/`cudaErrorUnknown` in `compile_kernels()`, `Restart=on-failure`
brought it straight back up, and it crashed again. Observed: 32 restarts in
~3 minutes on 2026-09-12 before the driver finally came up.

`After=nvidia-persistenced.service` was added too, but that's only a
best-effort hint — `nvidia-persistenced` is a *system* unit and this is a
*user* unit (different systemd manager instances), so ordering isn't
guaranteed to carry across. The actual fix is `wait-for-gpu.sh` as
`ExecStartPre`: it polls `nvidia-smi -L` (an actual working-driver check, not
just "is the persistence daemon process running") every 2s for up to 180s
before the real `ExecStart` runs.
