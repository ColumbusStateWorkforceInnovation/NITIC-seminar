# Day 1: Flash Poll Quiz Content

*Instructor Note: Load these questions into the Flash Poll app (Quizler) before the afternoon session to run the "Dry-Run Relay" game.*

## Question 1
**What is the core philosophical difference between a traditional Virtual Machine and a Docker Container?**
- A) Containers require their own dedicated Guest OS kernel.
- B) Containers share the Host OS kernel and only package the application space. *(Correct)*
- C) VMs are faster to start up than Containers.
- D) Containers cannot run on Windows or Mac.

## Question 2
**You built a custom web server image and want to run it in Kubernetes. Why does Kubernetes wrap your container inside a 'Pod'?**
- A) Because 'Pod' is a nautical term and Docker doesn't use it.
- B) A Pod allows multiple tightly-coupled containers to share the same local network and storage volume. *(Correct)*
- C) Pods automatically encrypt the container's traffic.
- D) Containers are not allowed to have IP addresses, only Pods are.

## Question 3
**You want to deploy an Nginx pod, but you don't want to type out 30 lines of YAML from memory. What is the correct 'dry-run' command to generate the manifest?**
- A) `kubectl generate pod nginx --image=nginx > pod.yaml`
- B) `kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml` *(Correct)*
- C) `kubectl create pod nginx --dry-run=true > pod.yaml`
- D) `docker run nginx --export-yaml > pod.yaml`

## Question 4
**You used `kubectl exec -it my-pod -- /bin/sh` to log into your running pod and manually installed `curl` using `apt-get install curl`. You then delete the pod and recreate it from the original YAML. What happens to `curl`?**
- A) It is still installed because Kubernetes saves your changes to the hard drive.
- B) It is gone. The container was recreated from the original, immutable image. *(Correct)*
- C) It triggers a CrashLoopBackOff error.
- D) It throws an error asking you to commit the changes first.

## Question 5
**Which command would you use to list all pods across every single namespace in the cluster to find a hidden treasure?**
- A) `kubectl get pods --all`
- B) `kubectl get pods -A` *(Correct)*
- C) `kubectl describe pods *`
- D) `kubectl get all-pods`
