# How to register the hooks in `~/.claude/settings.json`

Type: How-To. Goal: make Claude Code run the five scripts in `claude/hooks/`.

`install.sh` links the scripts into `~/.claude/hooks/` but does not register them, because `~/.claude/settings.json` is a real file with machine-specific paths and is not managed from this repo. What each hook does is specified in `docs/reference/hooks.md`.

## Before you start

- Run `./install.sh` so the five scripts exist in `~/.claude/hooks/`.
- Open `~/.claude/settings.json` and find the `hooks` object. Create it if it is missing.

## Steps

1. Add these entries to the `hooks` object. If an event already has a list, append the new items to that list instead of replacing it.

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/git-guard.sh"
             }
           ]
         },
         {
           "matcher": "Monitor",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/monitor-guard.sh"
             }
           ]
         },
         {
           "matcher": "Edit|Write|MultiEdit",
           "hooks": [
             { "type": "command", "command": "$HOME/.claude/hooks/red-gate.sh" }
           ]
         }
       ],
       "PostToolUse": [
         {
           "matcher": "Edit",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/test-guard.sh"
             }
           ]
         },
         {
           "matcher": "Agent",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/agent-guard.sh"
             }
           ]
         },
         {
           "matcher": "Bash",
           "hooks": [
             { "type": "command", "command": "$HOME/.claude/hooks/red-gate.sh" }
           ]
         }
       ],
       "PostToolUseFailure": [
         {
           "matcher": "Bash",
           "hooks": [
             { "type": "command", "command": "$HOME/.claude/hooks/red-gate.sh" }
           ]
         }
       ],
       "Stop": [
         {
           "hooks": [
             { "type": "command", "command": "$HOME/.claude/hooks/red-gate.sh" }
           ]
         }
       ]
     }
   }
   ```

2. Leave out the four `red-gate.sh` entries if you do not want the RED gate. The gate does nothing in a project without `.claude/red-gate.json` either way.
3. Check that the file is still valid JSON:

   ```bash
   python3 -m json.tool ~/.claude/settings.json > /dev/null && echo valid
   ```

4. Start a new session. Hooks are read at session start.

## Check that it works

Ask Claude to run `git add -A` in any repository. `git-guard` refuses it with a message beginning `BLOCKED by git-guard`. If the command runs, the `PreToolUse` entry for `Bash` is not registered or the path in `command` is wrong.

To gate a project with `red-gate`, continue with `docs/howto/use-the-red-gate.md`.
