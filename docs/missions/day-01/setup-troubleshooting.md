# Day 1 Setup — Troubleshooting & Instructor Crib Sheet

A quick reference for the Day 1 morning VM build. The first section is **pre-seminar prep**; the rest is a **symptom → cause → fix** index to keep open during the lab.

The setup path — VirtualBox → Ubuntu install → `setup-client.sh` → `verify-client.sh` — has been run end-to-end and works cleanly. This sheet is here for the odd machine that misbehaves, not because the morning is expected to be rough.

---

## Pre-Flight Checklist (before June 1)

1. **Test one classroom desktop.** Install VirtualBox and confirm a 64-bit Ubuntu VM boots at normal speed (no 🐢 turtle icon). If 64-bit options are missing or the VM crawls, it's a Hyper-V/BIOS issue — see [below](#only-32-bit-options-or-the-vm-is-slow) — and the fix needs administrator rights, so loop in CSCC IT early.
2. **Stage the Ubuntu ISO locally.** Pre-copy `ubuntu-24.04-desktop-amd64.iso` to each desktop's `Downloads` folder, a USB drive, or a fast local share. Thirty students downloading a ~6 GB ISO at once will saturate the campus link — easy to avoid.
3. **Confirm VirtualBox is available** on the desktops (7.1 or newer), or stage the installer.
4. **Run the whole path once on a classroom desktop, on the classroom network.** `setup-client.sh` reaches `download.docker.com`, `github.com`, `dl.k8s.io`, `get.helm.sh`, `starship.rs`, and `raw.githubusercontent.com`. Confirm the campus firewall/proxy allows them.
5. **Confirm `SERVER_IP`** and write it on the board. The lab domain (`wagbiz.org`) is now the built-in default, so students only need the IP.

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

### `setup-client.sh` exits immediately: "SERVER_IP is not set"

**Cause:** The script was run without `SERVER_IP`.

**Fix:** Re-run with the IP from the board:

```bash
export SERVER_IP=<the IP on the board>
bash scripts/setup-client.sh
```

### Lab services won't load in the browser

**Symptom:** `harbor.wagbiz.org` / `docs.wagbiz.org` won't open in Firefox inside the VM.

**Cause:** `setup-client.sh` didn't finish, so the lab subdomains were never added to `/etc/hosts`.

**Fix:** Re-run `setup-client.sh` (it's idempotent — safe to run again) and watch it report the `/etc/hosts` entries. To check by hand: `grep wagbiz /etc/hosts`. If you're running a domain other than the `wagbiz.org` default, students must `export LAB_DOMAIN=<your domain>` before running the script.

### `docker: permission denied` in Lab 01

**Cause:** `setup-client.sh` added the user to the `docker` group, but group membership only applies to a new login session.

**Fix:** Log out of Ubuntu and back in (or reboot the VM). Quick in-place fix: `newgrp docker`.

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
