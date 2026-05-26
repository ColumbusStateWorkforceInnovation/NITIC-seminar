# Lab 01: The Radar Room

Operating a ship via the command line (`kubectl`) is powerful, but looking at raw text output all day is exhausting. It's time to step into the Radar Room and use a visual dashboard.

In this lab, you will learn how to use `k9s`, a Terminal UI (TUI) that gives you a live, interactive dashboard of the entire Kubernetes cluster right from your SSH session.

## 🧑‍🏫 Instructor Superpower: The Teacher's Dashboard
*As an instructor, you never want to look over a student's shoulder to debug their code. With a shared cluster and `k9s`, you can instantly drop into any student's namespace from the podium, read their logs, and spot their typos before they even raise their hand.*

## Step 1: Firing up the Radar

1. Type `k9s` in your terminal and press Enter.
2. You will be greeted by the dashboard. Notice the top banner shows the cluster name and the current namespace.
3. **Change your view:** Press `:` (colon) to open the command prompt at the bottom of the screen. Type `ns` and hit Enter. You are now looking at a list of all namespaces in the cluster.
4. Use the arrow keys to highlight your personal namespace and hit Enter. You are now filtered to only see your ships!

## Step 2: The CrashLoopBackOff Speed Round!

Oh no! A rogue wave has hit the fleet! The Admiral just deployed a broken component into every single student's namespace. 

**Your Mission:**
1. You must use `k9s` to find the broken pod in your namespace. It will have a status of `CrashLoopBackOff` or `Error`.
2. Highlight the broken pod.
3. Press `l` (lowercase L) to view the live logs of that pod.
4. Read the error message in the logs to figure out exactly *why* the pod is crashing.
5. Be the first student to stand up and yell out the exact error message!

*(Hint: If the logs are moving too fast, press `s` to toggle auto-scroll, or use the arrow keys to scroll up).*

## Step 3: The Pod That Won't Die

Now that you've diagnosed the issue, let's try to clear the debris.
1. Press `Esc` to go back to the Pod view in `k9s`.
2. Highlight the broken pod.
3. Press `Ctrl-d` to delete it. A confirmation dialog will appear. Press Enter to confirm.
4. Watch closely... the pod terminates, and then — **a brand new broken pod appears in its place!**

What happened? The `leaky-ship` isn't a lone Pod — it's managed by a **Deployment**, the resilient manager you'll meet in Lab 02. The Deployment's whole job is to keep a pod running, so the instant you delete one, it spawns a replacement. You can't sink this ship by bailing water; you have to scuttle the whole vessel.

## Step 4: Scuttling the Whole Ship

To truly clear the wreckage, delete the **Deployment**, not the Pod.
1. Press `:` to open the command prompt, type `deploy`, and hit Enter. You are now in the Deployments view.
2. Highlight `leaky-ship`.
3. Press `Ctrl-d` and confirm. Now the Deployment *and* its pod are gone for good.

You just witnessed the core idea behind the very next lab: Deployments self-heal. You are now a certified Radar Operator. Keep `k9s` open in a separate terminal window or tab for the rest of the day to monitor your deployments!
