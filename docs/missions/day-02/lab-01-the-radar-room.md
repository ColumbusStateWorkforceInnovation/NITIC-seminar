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
5. The first student to stand up and yell out the exact error message wins a copy of the textbook!

*(Hint: If the logs are moving too fast, press `s` to toggle auto-scroll, or use the arrow keys to scroll up).*

## Step 3: Cleaning Up the Wreckage

Now that you've diagnosed the issue, we need to clear the debris.
1. Press `Esc` to go back to the Pod view in `k9s`.
2. Highlight the broken pod.
3. Press `Ctrl-d` to delete it. A confirmation dialog will appear. Press Enter to confirm.
4. Watch as the cluster terminates the pod.

You are now a certified Radar Operator. Keep `k9s` open in a separate terminal window or tab for the rest of the day to monitor your deployments!
