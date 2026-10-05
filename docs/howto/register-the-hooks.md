# How to register the hooks in `~/.claude/settings.json`

Type: How-To. Goal: make Claude Code run the five scripts in `claude/hooks/`.

`install.sh` links the scripts into `~/.claude/hooks/` but does not register them, because `~/.claude/settings.json` is a real file with machine-specific paths and is not managed from this repo. What each hook does is specified in `docs/reference/hooks.md`.

## Before you start

- Run `./install.sh` so the five scripts exist in `~/.claude/hooks/`.
- Have `python3` on your path.

## Steps

1. Optional: if you do not want the RED gate, delete the four `red-gate.sh` lines from the `WANT` list in step 2 before running it. The gate does nothing in a project without `.claude/red-gate.json` either way.
2. Run this script. It adds only the entries that are missing, so hooks you already registered stay as they are and running it twice changes nothing. It copies the file to `~/.claude/settings.json.bak` before writing, and it keeps the file's key order and escaping so a diff shows only the added entries.

   ```bash
   python3 - <<'EOF'
   import json, os, shutil

   path = os.path.expanduser("~/.claude/settings.json")
   raw = open(path).read()
   settings = json.loads(raw)

   WANT = [
       ("PreToolUse", "Bash", "git-guard.sh"),
       ("PreToolUse", "Monitor", "monitor-guard.sh"),
       ("PreToolUse", "Edit|Write|MultiEdit", "red-gate.sh"),
       ("PostToolUse", "Edit", "test-guard.sh"),
       ("PostToolUse", "Agent", "agent-guard.sh"),
       ("PostToolUse", "Bash", "red-gate.sh"),
       ("PostToolUseFailure", "Bash", "red-gate.sh"),
       ("Stop", None, "red-gate.sh"),
   ]

   hooks = settings.setdefault("hooks", {})
   added = []
   for event, matcher, script in WANT:
       command = f"$HOME/.claude/hooks/{script}"
       entries = hooks.setdefault(event, [])
       if any(
           e.get("matcher") == matcher and any(h.get("command") == command for h in e.get("hooks", []))
           for e in entries
       ):
           continue
       entry = {"hooks": [{"type": "command", "command": command}]}
       if matcher:
           entry["matcher"] = matcher
       entries.append(entry)
       added.append(f"{event} {matcher or '-'} {script}")

   if added:
       shutil.copy(path, path + ".bak")
       with open(path, "w") as handle:
           text = json.dumps(settings, indent=2, sort_keys=True, ensure_ascii=False)
           handle.write(text.replace("&", "\\u0026").replace("<", "\\u003c").replace(">", "\\u003e") + "\n")
   print("added:" if added else "nothing to add; already registered", *added, sep="\n  ")
   EOF
   ```

3. Check that the file is still valid JSON:

   ```bash
   python3 -m json.tool ~/.claude/settings.json > /dev/null && echo valid
   ```

4. Start a new session. Hooks are read at session start.

## Check that it works

Ask Claude to run `git add -A` in any repository. `git-guard` refuses it with a message beginning `BLOCKED by git-guard`. If the command runs, the `PreToolUse` entry for `Bash` is not registered or the path in `command` is wrong.

To gate a project with `red-gate`, continue with `docs/howto/use-the-red-gate.md`.
