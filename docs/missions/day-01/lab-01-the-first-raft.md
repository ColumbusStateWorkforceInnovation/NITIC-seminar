# Lab 01: The First Raft

The ship has sunk. You're stranded. To survive, you need to build a raft. In the Cloud-Native world, your fundamental building block is the **Container**.

In this lab, you will build a custom web server container (your raft), hoist your unique flag on it, and push it to the island's central harbor.

## Step 0: Make Camp

All of today's work lives in `~/lab/` — your default workspace. `setup-client.sh` created the directory and dropped a **VS Code workspace** in it. Move in and open it:

```bash
cd ~/lab
code lab.code-workspace
```

VS Code will open with `~/lab/` as the root and may prompt you to install a few recommended extensions (Docker, Kubernetes, YAML, indent-rainbow, Prettier) — click **"Install"** if so. If a "Do you trust the authors" prompt appears, click **"Yes, I trust the authors"**.

The `Dockerfile`, `index.html`, and `AGENTS.md` you're about to create all belong here, side by side.

## 🤖 Instructor Superpower: The Socratic Boatswain

*As educators, we know students will use AI. Instead of fighting it, we will harness it. We have deployed a local, private LLM running right here on the island — it runs entirely on the cluster, so nothing typed into it ever leaves the room. We are going to configure it to act as your Teaching Assistant.*

1. In VS Code (from Step 0), open `AGENTS.md` from the file explorer on the left — it's empty right now. Paste the following rules — this file is the Boatswain's rule book:

   ```markdown
   --8<-- "examples/agents-md/day-1-the-salty-boatswain.md"
   ```

2. Wake the Boatswain: `hail`.

   Your prompt should change from `$` to `boatswain>` — that's how you know Silas is loaded. (`hail` is a tiny wrapper `setup-client.sh` installed at `/usr/local/bin/hail`; it runs `aichat -r boatswain` against the role file `~/.config/aichat/roles/boatswain.md`, which is symlinked to the `~/lab/AGENTS.md` you just edited. Edit AGENTS.md and re-run `hail` to pick up new rules.)

3. Inside the `boatswain>` REPL, type `.info` to verify you are connected to the island's `qwen3:8b` model.

## Step 1: Drafting the Blueprint (Dockerfile)

You need to write a `Dockerfile` that:

1. Uses the official `nginx:alpine` base image.
2. Copies a local `index.html` file into the Nginx public HTML directory (`/usr/share/nginx/html`).

**The Catch:** We aren't going to give you the syntax!
Inside your `boatswain>` REPL (started with `hail`), ask: *"Hey Boatswain, how do I write a Dockerfile to run Nginx and copy my own index.html file into it?"*

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
**Once your push succeeds**, your image is visible in the shared `raft-fleet` project at `harbor.{{ lab_domain }}`. The cluster will pull it from there in Lab 02 this afternoon.
