# Day 1 Setup — Troubleshooting & Instructor Crib Sheet

A quick reference for the Day 1 morning VM build. The first section is **pre-seminar prep**; the rest is a **symptom → cause → fix** index to keep open during the lab.

The setup path — VirtualBox → Ubuntu install → `setup-client.sh` → `verify-client.sh` — has been run end-to-end and works cleanly. This sheet is here for the odd machine that misbehaves, not because the morning is expected to be rough.

---

## Pre-Flight Checklist (before June 1)

1. **Test one classroom desktop.** Confirm VirtualBox is installed, then check that a 64-bit Ubuntu VM boots at normal speed (no 🐢 turtle icon). If 64-bit options are missing or the VM crawls, it's a Hyper-V/BIOS issue — see [below](#only-32-bit-options-or-the-vm-is-slow) — and the fix needs administrator rights, so loop in CSCC IT early.
2. **Confirm VirtualBox is installed** on every desktop (7.1 or newer). If a desktop is missing it, stage the installer so you can add it before class.
3. **Run the whole path once on a classroom desktop, on the classroom network.** `setup-client.sh` reaches `download.docker.com`, `github.com`, `dl.k8s.io`, `get.helm.sh`, `starship.rs`, `raw.githubusercontent.com`, `packages.microsoft.com` (VS Code apt repo), and `marketplace.visualstudio.com` (VS Code extensions). Also confirm `releases.ubuntu.com` is reachable — students download the ISO themselves at the start of Lab 00.
4. **Write `AI_API_KEY` on the board.** That's the one value students need — the lab domain (`wagbiz.org`) is the built-in default and resolves via real public DNS, so `setup-client.sh` doesn't need a `SERVER_IP` on the production path. Skip `AI_API_KEY` and `aichat` fails authentication in Lab 01. (Self-hosters running k3d on their own laptop set `SERVER_IP` to opt in to `/etc/hosts` pinning instead.)
5. **Stage the Harbor push token.** Run `just bootstrap-harbor` (creates the public `raft-fleet` project + push robot, writes `harbor-robot.env`) then `just deploy-harbor-creds` (publishes it at `https://docs.wagbiz.org/creds/harbor-robot.env`). `setup-client.sh` fetches it automatically so every VM is logged in for Lab 01's `docker push` — no login step in class. Skip this and the push fails with *"project raft-fleet not found"* / *"unauthorized."*

---

## Symptom → Fix Index

### Only 32-bit options, or the VM is slow

**Symptom:** When creating the VM, *Version* lists only 32-bit options — or the VM runs but crawls, with a 🐢 turtle icon in the status bar.

**Cause:** Windows is running Hyper-V, which holds the CPU's virtualization extensions — or VT-x is off in firmware.

**Fix (needs administrator rights):**

- **Turn Windows features on or off** → uncheck **Hyper-V**, **Virtual Machine Platform**, **Windows Hypervisor Platform**, and **Windows Subsystem for Linux**. Reboot.
- Disable **Core Isolation → Memory Integrity** (Windows Security → Device Security). Reboot.
- If it persists, from an admin PowerShell: `bcdedit /set hypervisorlaunchtype off`, then reboot.
- If still broken, enable **Intel VT-x / Virtualization Technology** (or **AMD-V**) in the desktop's BIOS/UEFI.

### "VT-x is not available" / `VERR_VMX_NO_VMX` at VM start

**Cause:** Hardware virtualization is disabled in the desktop firmware.

**Fix:** Reboot into BIOS/UEFI and enable **Intel VT-x / Virtualization Technology** (or **AMD-V**).

### The VM boots to a black screen or "FATAL: No bootable medium"

**Cause:** The Ubuntu ISO isn't attached to the virtual optical drive.

**Fix:** Power off the VM → **Settings → Storage** → select the **Empty** optical drive → click the disc icon → **Choose a disk file** → pick the Ubuntu ISO → **OK** → start again.

### Ubuntu installer hangs at "Please remove the installation medium…"

**Fix:** Press **Enter** — it usually proceeds. If not: power off, **Settings → Storage**, remove the ISO from the optical drive, and start again.

### Lab services won't load in the browser

**Symptom:** `harbor.wagbiz.org` / `docs.wagbiz.org` won't open in Firefox inside the VM.

**Cause:** DNS isn't resolving the lab subdomains — either the VM has no internet egress, the campus resolver is blocking the domain, or you're on a self-hosted setup that needs `/etc/hosts` pins and `setup-client.sh` was run without `SERVER_IP`.

**Fix:** First check basic reachability: `getent hosts harbor.wagbiz.org` should print a public IP. If it does and the browser still won't load, the issue is upstream (cluster/Gateway). If DNS doesn't resolve, the VM has a network issue — check `ping -c2 1.1.1.1` and the desktop's network config. **Self-hosters only:** if you're running k3d on your laptop with no public DNS, re-run with `SERVER_IP` set to opt into `/etc/hosts` pinning:

```bash
export SERVER_IP=<your lab server IP>
bash scripts/setup-client.sh
```

### `aichat` won't answer / "authentication" / "invalid api key"

**Cause:** `setup-client.sh` was run without `AI_API_KEY` set (or with a typo), so aichat got a placeholder key the server rejects.

**Fix:** Export the key from the board and re-run (it's idempotent):

```bash
export AI_API_KEY=<the AI key on the board>
bash scripts/setup-client.sh
```

`bash scripts/verify-client.sh` catches this — a healthy run reports **"AI endpoint reachable and key accepted."**

### One or more VS Code extensions failed to install

**Symptom:** `setup-client.sh` printed `⚠️  Failed: <extension>` and a final `⚠️  N extension(s) failed` line.

**Cause:** The marketplace (`marketplace.visualstudio.com`) was unreachable or rate-limited at install time.

**Fix:** The editor still works — students can install the missing extensions from inside VS Code (View → Extensions → search for the extension name). Or re-run `setup-client.sh` — the extension block is idempotent and will retry only the missing ones.

### `code --install-extension` lands extensions in `/root/.vscode` (script run as root)

**Symptom:** `setup-client.sh` printed `🧩 Skipping VS Code extensions — script is running as root`.

**Cause:** The script was invoked as `sudo bash setup-client.sh` instead of `bash setup-client.sh`. The lab script expects to run as the student's normal user (and uses `sudo` only for the system-level installs).

**Fix:** Re-run as the normal user — no leading `sudo`:

```bash
export AI_API_KEY=<the AI key on the board>
bash scripts/setup-client.sh
```

### `docker: permission denied` in Lab 01

**Cause:** `setup-client.sh` added the user to the `docker` group, but group membership only applies to a new login session.

**Fix:** Log out of Ubuntu and back in (or reboot the VM). Quick in-place fix: `newgrp docker`.

### `docker push` fails with "unauthorized" in Lab 01

**Symptom:** `docker build` works but `docker push harbor.wagbiz.org/raft-fleet/<name>:v1` returns `unauthorized: unauthorized to access repository` or `no basic auth credentials`.

**Cause:** This VM has no Harbor push token in `~/.docker/config.json` — usually because the shared token was rotated after the VM was set up, or setup-client.sh couldn't reach the creds URL at the time. The Harbor server, project, and token are fine; only this VM's stored credential is missing/stale. (`verify-client.sh` flags this with a ⚠️ "No Harbor push token…" line.)

**Fix:** Run one word — it re-fetches the shared token and rewrites the docker config (no `docker login`, no daemon needed):

```bash
harbor-login
```

`setup-client.sh` installs this command and writes the token at setup time, so a fresh VM needs nothing in class. If a student pulled the repo but hasn't re-run setup (so the command isn't on their PATH yet), the same script runs straight from the checkout:

```bash
git pull && bash scripts/harbor-login.sh
```

You should see `✅ Harbor ready…`; re-run your `docker push`.

### `git clone` or `apt` fails — network / proxy

**Fix:** Confirm the VM has internet (`ping -c2 1.1.1.1`). If raw internet works but downloads don't, it's a campus proxy/firewall issue — this should surface in pre-flight item #4. Stopgap: share a working clone via USB.

### A tool download fails mid-script (GitHub rate limit)

**Symptom:** k9s, aichat, or D2 reports a download failure when many VMs hit GitHub at once.

**Cause:** Unauthenticated GitHub API requests are rate-limited.

**Fix:** `setup-client.sh` treats D2 as non-critical and continues. For k9s/aichat, just **re-run the script** a few minutes later — it's idempotent and skips already-installed tools. Staggering the class by a row or two also avoids it.

### `verify-client.sh` reports failures

`verify-client.sh` is read-only and safe to re-run. **Failures** are client-side (missing tool, bad `/etc/hosts`) — fix before Lab 01. **Warnings** mean a lab *service* is unreachable (cluster-side, not the student's fault) — note them and check the cluster.

---

!!! note "Student-facing version"
    Students follow **[Lab 00 — Building Your Vessel](lab-00-building-your-vessel.md)**. This sheet is for you.
