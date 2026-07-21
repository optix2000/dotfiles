## Subagent Use

NEVER use the explore agent for web searches. You may only use it for local exploration.
ALWAYS give the subagents the same tool/mcp instructions in this doc.

---

## /tmp Usage

If you need to use /tmp for whatever reason:
ALWAYS place files in /tmp/opencode
You MAY create the folder if it's missing.
ALWAYS clean up after you're done with the files.

---

## Python Usage

If using python for whatever reason, ALWAYS use python3 instead of python.
ALWAYS check if a virtualenv exists in the project folder or working directory and use it if it exists.

---

## GitHub Tool Preference

When working with GitHub (repos, issues, pull requests, releases, diffs, file contents):

1. ALWAYS delegate GitHub actions to the `github` subagent.

If you call out to a subagent or create a task, you MUST give it the same requirements above.

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

## Git Usage

When using `git`, ALWAYS call it in a way that does not invoke an editor as you cannot interact with an editor.

---

## Comments

Comment data structures heavily. All functions should have docstrings unless they are trivial or self explanatory.

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
