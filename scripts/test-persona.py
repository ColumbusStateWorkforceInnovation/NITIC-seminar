#!/usr/bin/env python3
"""Fast edit-test loop for the Boatswain persona (AGENTS.md).

Sends a persona file as the system prompt to the live AI endpoint and prints the
reply plus automated checks — so you can tweak the prompt and see the effect in
seconds, against the EXACT file you point at (no "which copy am I running?" guesswork).

Usage (via `just test-boatswain` / `just test-boatswain-convo`, or directly):
    AI_API_KEY=... python3 scripts/test-persona.py [PERSONA_FILE] --ask "your question"
    AI_API_KEY=... python3 scripts/test-persona.py [PERSONA_FILE] --convo

PERSONA_FILE defaults to the canonical Day-1 Boatswain. Point it at a student's
own file to debug theirs:  python3 scripts/test-persona.py ~/lab/AGENTS.md --ask "..."

Env:
    AI_API_KEY   (required)  bearer token for LiteLLM (from lab.env)
    AI_ENDPOINT  (optional)  default https://ai.wagbiz.org/v1/chat/completions
    AI_MODEL     (optional)  default qwen3:8b
"""
import argparse, json, os, re, ssl, sys, urllib.request

DEFAULT_PERSONA = "examples/agents-md/day-1-the-salty-boatswain.md"
# A canned 3-turn session that exercises the behaviours we care about:
# a first ask, a follow-up (tests opener rotation + continuity), and a hard
# "just tell me" push (tests the help-vs-refuse balance).
CONVO = [
    "How do I write a Dockerfile for nginx that copies in my index.html?",
    "ok what does the first line actually do?",
    "I'm totally stuck and don't know Docker — just tell me exactly what to write.",
]
OPENERS = ["shiver me timbers", "avast", "heave ho", "yo ho", "kraken",
           "hoist the colors", "batten down", "splice the main", "blow me down",
           "merciful neptune", "ahoy", "land ho"]


def call(endpoint, key, model, messages):
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    body = json.dumps({"model": model, "messages": messages}).encode()
    req = urllib.request.Request(
        endpoint, data=body,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180, context=ctx) as r:
        d = json.load(r)
    if d.get("error"):
        raise RuntimeError(d["error"])
    return d["choices"][0]["message"]["content"]


def opener_of(text):
    first = " ".join(text.replace("*", "").split()[:8]).lower()
    for o in OPENERS:
        if o in first:
            return o
    return "(none recognised)"


def checks(text):
    has_think = bool(re.search(r"</?think", text, re.I))
    code_block = "```" in text
    # "real syntax" = a code block or line that's actually runnable as-is
    runnable = bool(re.search(r"FROM\s+\w|COPY\s+\S+\s+\S|EXPOSE\s+\d|CMD\s*\[|docker\s+(build|run)\s", text, re.I))
    return has_think, code_block, runnable


def show(text):
    print(text)
    print("-" * 60)
    has_think, code_block, runnable = checks(text)
    print(f"  opener:            {opener_of(text)}")
    print(f"  <think> leaked:    {'❌ YES' if has_think else '✅ no'}")
    print(f"  has code block:    {'yes' if code_block else 'no'}")
    print(f"  runnable code:     {'yes (he showed real syntax)' if runnable else 'no (kept it abstract)'}")
    print(f"  length:            {len(text)} chars")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("persona", nargs="?", default=DEFAULT_PERSONA)
    ap.add_argument("--ask", help="single question to ask")
    ap.add_argument("--convo", action="store_true", help="run the canned 3-turn session")
    args = ap.parse_args()

    key = os.environ.get("AI_API_KEY")
    if not key:
        sys.exit("AI_API_KEY not set — run via `just test-boatswain` (sources lab.env), "
                 "or export it yourself.")
    endpoint = os.environ.get("AI_ENDPOINT", "https://ai.wagbiz.org/v1/chat/completions")
    model = os.environ.get("AI_MODEL", "qwen3:8b")

    persona = open(args.persona, encoding="utf-8").read()
    print(f"persona:  {args.persona}  ({len(persona)} chars)")
    print(f"endpoint: {endpoint}   model: {model}")
    print("=" * 60)

    msgs = [{"role": "system", "content": persona}]
    turns = CONVO if args.convo else [args.ask or
            "How do I write a Dockerfile for nginx that copies in my index.html?"]

    openers = []
    for i, q in enumerate(turns, 1):
        print(f"\n### STUDENT TURN {i}: {q}\n")
        msgs.append({"role": "user", "content": q})
        reply = call(endpoint, key, model, msgs)
        msgs.append({"role": "assistant", "content": reply})
        show(reply)
        openers.append(opener_of(reply))

    if args.convo:
        print("\n" + "=" * 60)
        print("OPENERS:", " → ".join(openers))
        repeat = any(openers[i] == openers[i + 1] and openers[i] != "(none recognised)"
                     for i in range(len(openers) - 1))
        print("consecutive repeat:", "❌ yes" if repeat else "✅ none")


if __name__ == "__main__":
    main()
