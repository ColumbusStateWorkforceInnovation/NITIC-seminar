# Expanded Labs & Challenges

This document tracks the hands-on cluster exploration labs meant to accompany the daily curriculum. These labs emphasize practical `kubectl` skills, resource management, and CKA-style troubleshooting, while maintaining the Admiral Bash theme.

---

### Day 1: Sinking & Bailing (Exec & Logs)

**1. Local Exploration Vessel (Exec)**

* **Mission**: The main ship is down. Prove you can survive by launching a temporary, disposable raft to explore the waters.
* **Task**: Spawn a temporary diagnostic pod.
* **Action**: Have students run `kubectl run -it --rm bash-boat --image=busybox -- sh`. Once inside the container shell, have them ping an external domain (e.g., `google.com`) and run `top` to observe that they are running in an isolated process tree. This proves they aren't on the host VM anymore.
* **🧑‍🏫 Instructor Superpower (The Disposable Sandbox)**: Instructors hate when students permanently corrupt a lab VM. Emphasize that `kubectl run --rm` gives students a fully functional Linux sandbox that *instantly evaporates* the second they exit. Zero cleanup required.

**2. Inspect the Broken Raft (Logs/Describe)**

* **Mission**: A raft was sent out, but it keeps sinking (CrashLoopBackOff). 
* **Task**: Determine *why* the ship is sinking.
* **Action**: Prior to class, the Instructor deploys a faulty YAML (a pod that continuously runs `exit 1`). Students must use `kubectl describe pod broken-raft` to see the event stream, and `kubectl logs broken-raft` to diagnose the failure, simulating real-world crash recovery.
* **🧑‍🏫 Instructor Superpower (The Ultimate Audit Trail)**: You don't have to guess what a student did wrong locally. You can pull the logs or events directly from the cluster control plane to see exactly why their script failed, without ever touching their keyboard.

---

### Day 2: The Radio Deck & Cargo Holds (Port-Forward & Stateful Exec)

**1. Pirate Radio (Port Forwarding)**

* **Mission**: Someone is broadcasting pirate radio signals on the island, but the service isn't exposed to the open ocean (no NodePort or LoadBalancer). 
* **Task**: Use a secure tunnel to access the hidden frequency.
* **Action**: Have the instructor deploy a hidden web pod (e.g., Nginx with a customized `index.html` displaying a fun pirate joke or a secret code snippet). Students use `kubectl port-forward pod/pirate-radio 8080:80` to securely tunnel traffic and access the broadcast locally on their laptops. 
* **🧑‍🏫 Instructor Superpower (Secure Grading Access)**: How does an instructor look at a student's running web assignment without asking IT to open 30 public IP addresses? `kubectl port-forward` lets an instructor securely tunnel directly into a student's private namespace to review their work from the teacher's laptop.

**2. Message in a Bottle (DB Entry)**

* **Mission**: Leave a permanent mark on the island for other survivors to find.
* **Task**: Connect directly into the persistent storage engine via CLI.
* **Action**: Within their 3-Tier application alliance, Student A (database/cache) runs `kubectl exec -it <db-pod> -- redis-cli` (or Postgres equivalent). They manually insert a key called `bottle` with a secret message. Student C (the UI) then reloads their frontend to verify the message successfully traversed the internal K8s Services!
* **🧑‍🏫 Instructor Superpower (Stateful Verification)**: Proves to the faculty that Kubernetes isn't just for stateless web servers; they can confidently host full database environments for their backend courses and securely interact with them.

---

### Day 3: Mutiny & Advanced Navigation

**1. Ghost Ship (ArgoCD Drift)**

* **Mission**: Prove the Automated Shipyards (ArgoCD) are immune to direct mutiny.
* **Task**: Attempt to manually override the declarative state and watch ArgoCD fight back.
* **Action**: Have students use `k9s` or `kubectl edit deployment` to manually scale their replicas from 2 to 10. ArgoCD will instantly detect the "Drift" (Mutiny). The students then click `Sync` in ArgoCD, watching it mercilessly downscale the deployment back to the desired Git state, cementing the concept of a single source of truth.
* **🧑‍🏫 Instructor Superpower (The Indestructible Lab)**: If a student accidentally deletes half the resources for their assignment, the instructor doesn't have to "reset the VM image." ArgoCD spots the drift and instantly heals the lab back to the Git baseline.

**2. AI Sonar Data (Advanced Query Builder - CKA Prep)**

* **Mission**: The logs are too dense to read manually. You need advanced sonar to filter the noise.
* **Task**: Use an AI Assistant to quickly build complex `kubectl` output formatting commands.
* **Action**: *Instructor Note: JSONPath filtering is heavily tested and required on the CKA exam!* Have students ask their LLM: *"Write a `kubectl` command using custom-columns or jsonpath that lists only the names of the pods and the images they are running, sorted by creation time."* This teaches them not to memorize arbitrary syntax, but to confidently map AI responses to high-value certification skills.
* **🧑‍🏫 Instructor Superpower (Teaching Synthesis)**: JSONPath is notoriously ugly to memorize. Instructors learn they can teach students to use AI to build complex queries, allowing them to focus class time on *what* the data means, rather than *how* to parse JSON.

---

### Day 4: Admiral's Security Review

**1. Sunken Treasure (PVC Recovery & Limits)**

* **Mission**: The Chaos Pirate sank your database, but the treasure chest (Data) is still chained to the sea floor (PersistentVolume).
* **Task**: Write the GitOps YAML to respawn the database pod and successfully mount the existing `PersistentVolumeClaim`. Prove the data survived the container's destruction.
* **Action**: 
    * **The Twist (Admission Controllers)**: To prevent rogue pods taking down the VM, the cluster uses an Admission Controller / LimitRange. The deployment *will be blocked* unless students explicitly define resource constraints. They must ensure their database recovery YAML includes `resources.requests` and `resources.limits` (e.g., cpu 200m, memory 256Mi) to pass Customs and recover their treasure.
* **🧑‍🏫 Instructor Superpower (Classroom Guardrails)**: This answers the IT department's biggest fear: "What if a student writes an infinite loop and crashes the shared server?" Resource Limits ensure that a runaway student assignment hits an artificial ceiling and is throttled before impacting the rest of the class.
