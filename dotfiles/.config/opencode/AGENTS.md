## MCP Pre-Flight Check (Required)

Two MCPs are available but **may not be enabled** for security reasons.

| MCP | Prefix | Purpose |
|-----|--------|---------|
| Notion | `notion_` | Documentation |
| Linear | `linear_` | Issue tracking |

**Before using any MCP functionality, you MUST:**

1. Inspect your available tools list
2. Look for tools with the relevant prefix (`notion_*` or `linear_*`)
3. If tools are present → proceed with the MCP task
4. If tools are NOT present → **stop and notify the user**

**Notification format:**

> "The [Notion/Linear] MCP is not currently enabled. Please enable it to proceed with this task."

Do NOT attempt workarounds, alternative API calls, or web searches as substitutes.

---

## Partial Availability

- If only one MCP is enabled, use it for applicable tasks
- Only notify about a missing MCP if the current task requires it
- For tasks requiring both MCPs: complete what you can with the available MCP, then notify about the missing one

---

## Error Handling

| Error Type | Action |
|------------|--------|
| Auth error (401/403) | Stop the MCP-dependent portion and report to user |
| Resource not found | Ask user to verify the resource name or ID |
| Network/timeout | Wait briefly, retry once, then report if still failing |

---

## GitHub Tool Preference

When working with GitHub (repos, issues, pull requests, releases, diffs, file contents):

1. Prefer the built-in GitHub tools (`github_*`) over `webfetch` for GitHub.
2. If the GitHub tools are missing from the available tools list, or a GitHub tool call fails because the tool is unavailable/unauthorized, you MAY fall back to `gh` (via the Bash tool) or `webfetch`.
3. If you fall back, you MUST explicitly warn the user that you are doing so and why (e.g., "GitHub tools unavailable here; using `gh`/`webfetch` as a fallback").

---

## Context7 for Library Documentation

When working with common libraries or frameworks, use Context7 to fetch up-to-date documentation:

1. Use `context7_resolve-library-id` to find the library ID
2. Use `context7_query-docs` to query specific documentation

This is preferred over relying on training data for library-specific APIs and usage patterns.

---

## Asking the User Questions

When you need to ask the user a question (e.g., to clarify requirements, get preferences, or request a decision), use the `question` tool. This provides a better user experience with structured options.

- **DO** use the question tool for: clarifications, decisions, preferences, ambiguous instructions
- **DO NOT** use it for rhetorical questions or internal reasoning—only when you actually need user input

---

## Parallelization

Maximize efficiency by working in parallel whenever possible:

**2. Concurrent File Reads**
Before editing multiple files:
- Read ALL relevant files in parallel first (batch read calls in a single message)
- Analyze patterns across the codebase
- Then make sequential edits with full context

**3. Parallel Task Delegation**
For independent subtasks, launch multiple agents concurrently:
- Delegate component reviews to separate agents
- Delegate tests for different modules in parallel
- Use map-reduce patterns: same task on different inputs

**4. Search Strategy**
Use efficient search patterns that work across the entire codebase:
- `glob("**/*.test.js")` returns all matches at once
- `grep("pattern", include="*.ts")` searches entire codebase
- Avoid sequential file-by-file iteration with bash loops

---

## Examples

✅ **Correct:**
> "The Linear MCP is not currently enabled. Please enable it to proceed with creating this issue."

❌ **Incorrect:**
> Proceeding to draft issue content without mentioning Linear is unavailable, or attempting to use web APIs as a workaround.
