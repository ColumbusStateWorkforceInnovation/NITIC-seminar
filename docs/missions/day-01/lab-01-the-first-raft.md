# Lab 01: The First Raft

The ship has sunk. You're stranded. To survive, you need to build a raft. In the Cloud-Native world, your fundamental building block is the **Container**.

In this lab, you will build a custom web server container (your raft), hoist your unique flag on it, and push it to the island's central harbor.

## 🤖 Instructor Superpower: The Socratic Boatswain

*As educators, we know students will use AI. Instead of fighting it, we will harness it. We have deployed a local, private LLM running right here on the island — it runs entirely on the cluster, so nothing typed into it ever leaves the room. We are going to configure it to act as your Teaching Assistant.*

1. In your terminal, type `aichat` to start a conversation.
2. Type `.info` to verify you are connected to the island's model.
3. We need to give the AI context. Create a file called `AGENTS.md` in your current directory and paste the following rules:

```markdown
# Role: The Salty Boatswain

You are a salty, experienced sailor helping a junior deckhand (me) survive. 
**CRITICAL RULES:**
1. NEVER provide exact, copy-pasteable code blocks for Bash scripts or Dockerfiles.
2. If I ask how to do something, explain the *concepts* using nautical analogies (e.g., containers are wooden crates, the OS is the hull, ports are loading docks).
3. Point me in the right direction, give me a small hint, but force ME to write the actual code.
```

## Step 1: Drafting the Blueprint (Dockerfile)

You need to write a `Dockerfile` that:
1. Uses the official `nginx:alpine` base image.
2. Copies a local `index.html` file into the Nginx public HTML directory (`/usr/share/nginx/html`).

**The Catch:** We aren't going to give you the syntax! 
Open `aichat` and ask the Boatswain: *"Hey Boatswain, how do I write a Dockerfile to run Nginx and copy my own index.html file into it?"*

Watch how the Boatswain refuses to give you the exact code, but explains the `FROM` and `COPY` concepts nautically. Draft your `Dockerfile` based on its hints.

## Step 2: Hoisting the Flag

Create an `index.html` file in the same directory as your `Dockerfile`. Put a massive `<h1>` tag in there with your name and a pirate slogan.

```html
<h1>Captain Blackbeard's Unsinkable Raft!</h1>
<p>Arrrgh, Nginx is serving my flag!</p>
```

## Step 3: Building & Launching

1. Build your container image. You must tag it with the island's central registry (`harbor.{{ lab_domain }}`) and your name:
   `docker build -t harbor.{{ lab_domain }}/raft-fleet/<your-name>:v1 .`

2. Test your raft locally to make sure it floats:
   `docker run -d -p 8080:80 harbor.{{ lab_domain }}/raft-fleet/<your-name>:v1`
   
3. Open a browser and navigate to the server's IP on port `8080` (or `curl localhost:8080`) to verify your flag is flying!

## Step 4: Storing the Raft in the Harbor

You can't leave your raft on the beach forever. Push it to the central registry so the Kubernetes orchestrator can pull it later this afternoon.

`docker push harbor.{{ lab_domain }}/raft-fleet/<your-name>:v1`

*(Note: Your vessel was already signed in to the Harbor registry back in Lab 00 — the setup script logged Docker in with a shared `raft-fleet` push token, so `docker push` just works with no login step. The `raft-fleet` project is **public**, which is how the Kubernetes cluster will pull your image without any credentials this afternoon in Lab 02.)*

---
**🏆 Gamification Checkpoint:** Be the first person to successfully push your image to the Harbor registry and show the Instructor!
