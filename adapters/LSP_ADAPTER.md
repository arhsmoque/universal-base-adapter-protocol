# LSP Adapter

Purpose: provide deterministic code navigation for agents.

## Required commands / tools

```text
get_definition(file, line, column)
get_references(file, line, column | symbol)
get_symbols(file)
get_workspace_symbols(query)
```

## Result rules

Return the standard result envelope with:

- target file and range;
- symbol name and kind;
- references with file/range/evidence;
- warnings when the language server is stale or unavailable;
- fallback hint when grep/search is required.

## Agent rule

Prefer LSP for code symbols. Use grep/search for prose, config, generated files, logs, and when the repository has no practical language server.
