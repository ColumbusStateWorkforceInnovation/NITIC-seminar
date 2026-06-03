# Lab 02: Deploying the Fleet

Yesterday, you deployed a standalone Pod. While a Pod is better than a raw Container, it still has a fatal flaw: if the node it's running on dies, the Pod dies with it and stays dead.

To build a resilient fleet, we need a **Deployment**. A Deployment is a Kubernetes manager that constantly monitors your Pods. If you ask for 3 replicas, and 1 dies, the Deployment will immediately spawn a new one to replace it.

## Step 1: Generating the Deployment

Just like yesterday, we aren't going to type out YAML from memory. We will ask Kubernetes to generate it for us.

1. Run the dry-run command to generate a Deployment for an Nginx web server:
   `kubectl create deployment my-fleet --image=nginx:alpine --dry-run=client -o yaml > deployment.yaml`
2. Open `deployment.yaml` in VS Code (click it in your `~/lab` workspace explorer panel). 
3. Find the `replicas: 1` line and change it to `replicas: 3`. You are commanding the cluster to ensure 3 identical ships are always sailing.
4. Apply the manifest:
   `kubectl apply -f deployment.yaml`
5. Check your `k9s` dashboard. You should see three Pods spinning up automatically!

## Step 2: The ConfigMap (Changing the Sails)

Hardcoding configuration into your container images is a bad practice. If you want to change the color of your sails, you shouldn't have to rebuild the entire ship. Instead, we use a **ConfigMap** to inject configuration at runtime.

1. We are going to generate a ConfigMap manifest using `aichat`. 
2. Open `aichat` and ask the Socratic Boatswain: *"Boatswain, how do I write a YAML manifest for a ConfigMap that contains a key called `MESSAGE_OF_THE_DAY` with a value of 'Beware the Kraken!'? "*
3. The Boatswain will guide you conceptually. Once you understand the structure, create a file called `configmap.yaml` and write the YAML.
4. Apply the ConfigMap:
   `kubectl apply -f configmap.yaml`

## Step 3: Injecting the ConfigMap

Now we need to wire the ConfigMap into our Deployment.

1. Open your `deployment.yaml` file.
2. Under the `containers` section, you need to add an `env` array to map the ConfigMap key to an environment variable inside the container.
3. If you don't know the exact syntax, ask the Boatswain: *"How do I inject a ConfigMap value as an environment variable in my Deployment YAML?"*
4. Apply the updated deployment:
   `kubectl apply -f deployment.yaml`
5. Watch your `k9s` dashboard. You will see the Deployment automatically terminate the old pods and spin up new ones with the injected configuration. This is called a "Rolling Update."

## Step 4: Verifying the Injection

Did the configuration actually make it into the ship? Let's check.

1. Use `k9s` to exec (shell) into one of your newly running pods (highlight the pod and press `s`).
2. Run the command `env | grep MESSAGE` inside the pod.
3. You should see `MESSAGE_OF_THE_DAY=Beware the Kraken!` printed on the screen.
4. Type `exit` to leave the pod.

You have successfully decoupled your configuration from your application code!
