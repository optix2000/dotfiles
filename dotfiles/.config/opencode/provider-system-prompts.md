## Provider System Prompts (Markdown Rules)

Global rules live in `~/.config/opencode/provider-system-prompts/` as one markdown file per rule.

Format
- YAML frontmatter at the top with exactly one of: `model` or `modelRegex`
- Optional: `flags` (regex flags), `enabled` (boolean)
- Body after the second `---` is the prompt template

Example
```md
---
model: openai/gpt-5.2
---

{{opencode:provider}}

Additional constraints for this model:
- Prefer small, focused diffs.
- Never run destructive git commands.
```

Placeholders
- `{{opencode:provider}}` expands to the default provider prompt
- `{{opencode:builtin:codex}}`, `{{opencode:builtin:beast}}`, `{{opencode:builtin:gemini}}`,
  `{{opencode:builtin:anthropic}}`, `{{opencode:builtin:qwen}}`
