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

## Context7 for Library Documentation

When working with common libraries or frameworks, use Context7 to fetch up-to-date documentation:

1. Use `context7_resolve-library-id` to find the library ID
2. Use `context7_query-docs` to query specific documentation

This is preferred over relying on training data for library-specific APIs and usage patterns.

---

## Examples

✅ **Correct:**
> "The Linear MCP is not currently enabled. Please enable it to proceed with creating this issue."

❌ **Incorrect:**
> Proceeding to draft issue content without mentioning Linear is unavailable, or attempting to use web APIs as a workaround.
