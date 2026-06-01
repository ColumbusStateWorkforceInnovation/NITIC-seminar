# Lab 00: Building Your Vessel

Before you can survive the island, you need a vessel. Every tool, every container, every command in this seminar runs inside a **Linux virtual machine** — your own private ship that lives on the classroom desktop but is completely separate from Windows.

In this lab you'll build an Ubuntu VM from scratch and run the one bootstrap script that turns a bare Linux box into a fully-stocked DevOps shipyard.

!!! note "Instructor Superpower: One VM to Rule Them All"
    This is the lab that earns its keep. By the end of the morning every student is on the **exact same Ubuntu version, the exact same shell, the exact same tool versions** — regardless of what Windows desktop they sat down at. No more "it works on mine." That is the whole point of a containerized, scripted classroom: you debug the *script* once, not thirty laptops forever.

---

## ⚓ Before You Cast Off

This lab is run **together, as a class** — your instructor will demo each part on the projector. Don't race ahead; if you get stuck, raise a hand.

You need **one value** from your instructor — write it down now, you'll need it in Part 4:

| You need | Looks like | Where to get it |
| :--- | :--- | :--- |
| **`AI_API_KEY`** | `sk-...` | On the whiteboard |

!!! note "Instructor — do this first"
    Write **`AI_API_KEY`** on the board before 9:00. You'll walk the class through downloading the Ubuntu ISO in Part 0. The [Setup Troubleshooting](setup-troubleshooting.md) sheet has the full pre-flight checklist.

---

## Part 0 — Start the Ubuntu Download (do this first!)

The Ubuntu installer is a ~6 GB file. Kick the download off **right now** so it finishes in the background while you build the VM in Part 1.

1. Open a browser on the Windows desktop and go to **<https://releases.ubuntu.com/24.04/>**.
2. Click **`ubuntu-24.04.4-desktop-amd64.iso`** (the desktop ISO) to start the download. It saves to your `Downloads` folder.
3. **Leave the download running** and continue with Part 1 below. You'll point VirtualBox at the file in a moment — if it's still downloading when you reach the ISO step, just wait for it to finish before continuing.

!!! note "Instructor"
    Kick the class off here right at 09:15. Everyone hits Download together, then we walk Part 1 (VirtualBox VM creation) while the ISO comes down. By the time you reach Part 1 step 2 (attach the ISO), most students' downloads will have finished or be close to it.

---

## Part 1 — Build the Hull (Create the VM)

Oracle VirtualBox is already installed on your classroom desktop — it's the software that lets your Windows desktop run a second computer (the "guest") inside a window. Open it from the Windows Start menu (type `VirtualBox` and press Enter). You should see the **VirtualBox Manager** window.

1. In VirtualBox Manager, click the **New** button (top toolbar).
2. **Name and Operating System:**
    - **Name:** `island-vessel`
    - **ISO Image:** click the dropdown → **Other...** → browse to **`Downloads\ubuntu-24.04.4-desktop-amd64.iso`** (the file you started downloading in Part 0). If it isn't there yet, wait for the download to finish before continuing this step.
    - VirtualBox should auto-detect **Type: Linux** and **Version: Ubuntu (64-bit)**.
    - ✅ **Tick the box "Skip Unattended Installation."** This is important — it lets you run the real Ubuntu installer yourself in Part 2.
3. Click **Next**. **Hardware:**
    - **Base Memory:** `8192 MB` (8 GB). If your desktop has only 8 GB of RAM total, use `4096 MB` instead.
    - **Processors:** `2` (or `4` if the slider's green zone allows it).
4. Click **Next**. **Virtual Hard Disk:**
    - Leave **"Create a Virtual Hard Disk Now"** selected.
    - Set the size to **`40 GB`**.
    - Leave **"Pre-allocate Full Size"** *unchecked* — the disk grows only as you use it.
5. Click **Next → Finish**.

Your new VM appears in the left-hand list. One more tweak before you start it:

6. Select **`island-vessel`** → click **Settings**:
    - **General → Advanced →** set **Shared Clipboard** to **Bidirectional** (lets you copy/paste between Windows and the VM).
    - **Network →** confirm **Attached to: NAT**. This is the default and is all you need — it gives the VM internet access.
    - Click **OK**.

!!! note "If the VM only offers 32-bit options, or runs slowly"
    On some Windows 11 machines, VirtualBox shows only **32-bit** guest options or runs with a 🐢 turtle icon — a sign that Hyper-V is competing for virtualization. The fix needs an administrator, so flag it to your instructor rather than struggling. See [Setup Troubleshooting](setup-troubleshooting.md#only-32-bit-options-or-the-vm-is-slow).

---

## Part 2 — Install Ubuntu (Launch the Ship)

1. Select **`island-vessel`** and click **Start** (the green arrow). A new window opens and boots from the ISO.
2. Wait for the Ubuntu installer to load, then:
    - Pick your **language** → **Next**.
    - Accessibility / keyboard layout → accept the defaults → **Next**.
    - Choose **"Install Ubuntu"** (not "Try Ubuntu").
    - Connection / "How would you like to install Ubuntu?" → **Interactive installation** → **Default selection**.
    - "Install third-party software" — leave it as-is → **Next**.
3. **Disk setup:** choose **"Erase disk and install Ubuntu."**
    !!! info "This is safe"
        This *only* erases the 40 GB virtual disk you just created — it **cannot touch Windows** or anything else on the desktop. The VM is fully sandboxed.
4. **Create your account:**
    - **Your name:** anything (e.g. your first name).
    - **Computer name:** `island-vessel`.
    - **Username:** something short and lowercase, e.g. `sailor`.
    - **Password:** pick something you'll remember — **you'll type it often** for `sudo`. This is a throwaway classroom VM, so keep it simple.
    - It's fine to select **"Log in automatically."**
5. Confirm your **timezone** → start the install. It runs for **10–20 minutes** — a good moment for the morning break.
6. When it says **"Installation complete — Restart now,"** click it. If the screen says *"Please remove the installation medium, then press ENTER"*, just press **Enter**. (VirtualBox normally ejects the ISO for you.)

The VM reboots into a fresh Ubuntu desktop. **You've launched your ship.** 🚢

---

## Part 3 — First Boot & Provisions

1. Log in (or it logs in automatically). Click through or close any "What's new" / online-account welcome screens.
2. Open a **Terminal**: press the **Super key** (the Windows key) and type `terminal`, then press Enter.
3. Bring the system up to date and install `git` so you can fetch the lab repo:

    ```bash
    sudo apt update
    sudo apt install -y git
    ```

    Enter your password when prompted (you won't see characters as you type — that's normal).

---

## Part 4 — Board the Shipyard (Bootstrap Script)

This is the step that does the heavy lifting. One script installs **Docker, git, kubectl, Helm, k9s, VS Code, the Fish shell, Starship, and aichat** — everything you need to sail through the next four days.

1. Clone the seminar repository:

    ```bash
    git clone https://github.com/ColumbusStateWorkforceInnovation/NITIC-seminar.git
    cd NITIC-seminar
    ```

2. Copy the **`AI_API_KEY` from the whiteboard**, then run the bootstrap script. Replace the placeholder with the real value:

    ```bash
    export AI_API_KEY=<AI_KEY>
    bash scripts/setup-client.sh
    ```

    The `AI_API_KEY` is what wires `aichat` to the island's AI engine (Part 6) — if you skip it, `aichat` won't be able to log in.

3. **Early prompt — don't walk away yet!** A few seconds in, the script asks **"🏴 What's your first name, sailor?"** Type your first name and press Enter — it personalises your crew credential card at the end and seeds your git identity. After that one prompt the rest is unattended.

4. The script prints its progress with ⚓ emoji. It takes **5–15 minutes** depending on the network. Along the way it also logs Docker into the island's **Harbor** registry for you (you'll see a `🔑 ... logged in to Harbor` line) so your first `docker push` in Lab 01 just works — no login to memorize. When you see **"⚓ Setup Complete! The shipyard is ready,"** you're almost there.

!!! warning "Log out and back in"
    The script adds you to the `docker` group, but that change only takes effect on a fresh login. **Log out of Ubuntu and log back in** (or just reboot the VM) before the next part — otherwise `docker` will complain about permissions in Lab 01.

---

## Part 5 — Inspect the Hull (Verify)

Run the self-check. It installs nothing — it just confirms every tool, certificate, and connection is shipshape:

```bash
cd ~/NITIC-seminar
bash scripts/verify-client.sh
```

A healthy run ends with all checks **passed**. If anything **fails**, flag it to your instructor and point them at the [Setup Troubleshooting](setup-troubleshooting.md) sheet — don't move on to Lab 01 with a broken hull.

---

## Part 6 — You're Afloat

Drop into your new shell:

```bash
fish
```

You should see the **Starship** prompt. Confirm the core tools came aboard:

```bash
k9s version
kubectl version --client
```

Both should print a version. You don't have cluster access yet — that's expected. You'll point `kubectl` and the `k9s` dashboard at the live island cluster in **Lab 02**, once your instructor has added you to Rancher.

### Hailing the Island's AI

Your toolkit also includes **`aichat`**, a command-line client already pointed at the island's private AI engine — a local LLM running on the cluster, so nothing you type ever leaves the island. Give it a quick hail:

```bash
aichat "Ahoy! In one short sentence, what is a Linux container?"
```

A one-sentence reply means `aichat` is wired to the island's AI engine and ready for duty. A couple more things worth knowing:

- Run `aichat` with **no arguments** to open an interactive session. Inside it, type `.info` to see exactly which model you're connected to, and `.exit` to leave.
- You don't have an `~/lab/AGENTS.md` file yet — that's deliberate. In **Lab 01** you'll create one to turn the AI into the **Socratic Boatswain**, your in-class teaching assistant that gives hints instead of answers. You'll summon him with the `hail` command (a tiny wrapper `setup-client.sh` installed for you).

If those three tools run, your vessel is seaworthy. Open **Day 1 → Lab 01 — The First Raft** and wait for the class. 🏴‍☠️

!!! tip "Two directories — know which is which"
    From here on, two directories sit side-by-side in your home:

    - **`~/NITIC-seminar/`** — the lab's **toolbox** (the cloned repo). The setup script, the verifier, and reference materials live here. You won't edit anything in it.
    - **`~/lab/`** — your **workshop**. Every file you create across the next four days (Dockerfiles, YAML, `AGENTS.md`, Helm charts) belongs here. Lab 01 opens it as a VS Code workspace.

---

## Optional — A More Comfortable Cabin

Not required for any lab, but nicer if you have a spare moment: **Guest Additions** gives you a resizable VM window and smoother mouse handling.

```bash
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
```

Then, in the VM window's menu bar: **Devices → Insert Guest Additions CD image...**, open the mounted disc in **Files**, and run the installer (or run it from a terminal in `/media/$USER/VBox_GAs.../`). Reboot the VM afterward.

---

## Your Island Toolbelt

Once your `/etc/hosts` is wired up by the bootstrap script, these services are reachable from **Firefox inside the VM**:

| Service | URL |
| :--- | :--- |
| **Mission Docs** (this site) | <https://docs.{{ lab_domain }}> |
| **Harbor** (container registry) | <https://harbor.{{ lab_domain }}> |
| **Rancher** (cluster UI / kubeconfig) | <https://rancher.{{ lab_domain }}> |
| **Flash Poll** (in-class quizzes) | <https://poll.{{ lab_domain }}> |
| **AI Engine** (the Socratic Boatswain) | <https://ai.{{ lab_domain }}/v1> |

---

!!! tip "Something not working?"
    Common snags — and fast fixes — are in the **[Setup Troubleshooting](setup-troubleshooting.md)** crib sheet. Flag anything you can't clear to your instructor.
