---
name: mcp-doctor
description: Diagnose MCP server connection failures and GitHub Packages auth in a fixed order, reporting PASS/FAIL plus the exact remediation. Use when an MCP server won't connect, returns -32000, or a plugin's tools are missing.
---

Diagnose MCP and GitHub Packages failures by working the checks **in order** and stopping at the
first FAIL — later checks assume earlier ones passed. Print `PASS` or `FAIL` for each with the
evidence, then the remediation command.

**Symptom, if given:** $ARGUMENTS

## Rules

- **Never use `2>/dev/null`.** A swallowed error here reads as "not installed" and sends the
  diagnosis down the wrong path — that exact mistake produced a false "nwave-ai is not installed".
- Mask secrets in output: `sed -E 's/(_authToken=).*/\1***MASKED***/'`. Never print a token.
- Report what you observed, not what you expect. If a check cannot run, say so rather than inferring.

## Check 0 — Is this actually an auth problem?

Some servers need an interactive OAuth flow and **no amount of token fixing will help**. Read
`~/.claude.json` for `mcpServers`, and note any server the session reports as requiring
authentication (e.g. Datadog, Wiz).

- If the failing server is OAuth-based: **stop here.** It needs `/mcp` in an interactive session, or
  `claude mcp`, or the claude.ai connector settings. Non-interactive sessions cannot complete it.
- `-32000` on a *plugin-provided* server (named `plugin_<plugin>_<server>`) usually means the plugin
  failed to build or its cache is stale — jump to Check 4.

## Check 1 — Registry mapping and token present

```
sed -E 's/(_authToken=).*/\1***MASKED***/' ~/.npmrc
```

- FAIL if the scope has no registry line (e.g. `@your-org:registry=https://npm.pkg.github.com`).
- FAIL if there is no `//npm.pkg.github.com/:_authToken=` line.
- **FAIL if the token is written as a bare `$GITHUB_TOKEN`.** npm expands `${GITHUB_TOKEN}` only —
  the bare form is sent literally and always 401s.
- Note, without failing, if the token is a literal value rather than `${VAR}`: it works, but it's a
  plaintext secret at rest, which may contradict a keychain/sops setup.

## Check 2 — The env var actually resolves

Only if `.npmrc` uses `${VAR}`. Confirm the variable is set and non-empty in the shell npm will
run in — not just in your interactive shell. FAIL on empty; `${}` expanding to nothing produces a
401 that looks identical to a wrong token.

## Check 3 — Token scopes and SSO authorisation

```
gh auth status
```

- FAIL if scopes lack `read:packages`. Packages auth is separate from `repo`.
- FAIL if the PAT is not SSO-authorised for the org. This is the check most often missed: the token
  is valid, scoped correctly, and still 403s until authorised for that specific organisation.
- Prove it end to end rather than trusting the scope list — fetch a known package's metadata from
  the registry and report the HTTP status.

## Check 4 — Plugin cache and build state

```
ls ~/.claude/plugins/
```

Compare `installed_plugins.json` against what's actually present in `cache/`. FAIL on a version-hash
mismatch or a plugin listed as installed with no built output. Remediation is to clear that plugin's
cache entry and reinstall — not to re-auth.

Also check `blocklist.json`: a local blocklist does **not** override org-managed
`remote-settings.json`, so an org-enabled plugin cannot be disabled locally.

## Check 5 — The package still exists where it's referenced

Confirm the package path in the registry still resolves. A renamed or unpublished package produces
an auth-shaped failure. Report the status code you actually received.

## Output

A table: check number, `PASS`/`FAIL`, the evidence observed, and the remediation command for any
FAIL. Then one sentence naming the single root cause — not a list of everything that could be wrong.
State explicitly which checks you could not run in this environment.
