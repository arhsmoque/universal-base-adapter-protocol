# LSP Adapter

Language Server Protocol navigation provides deterministic symbol-level code understanding. Use LSP-first before broad text search or manual file scanning when working in supported codebases.

---

## 1. When to use LSP navigation

| Need | LSP operation | Fallback |
|------|--------------|---------|
| Find where a function is defined | `textDocument/definition` | grep for exact symbol name |
| Find all callers of a function | `textDocument/references` | grep with word-boundary |
| List all symbols in a file | `textDocument/documentSymbol` | manual scan |
| List all symbols in a workspace | `workspace/symbol` | find + grep |
| Rename a symbol safely | `workspace/rename` (dry-run: inspect changes first) | manual search-and-replace with verification |
| Check for errors or warnings | `textDocument/diagnostic` | run lint command |

Use grep or text search only when: the language is unsupported, the LSP server is unavailable, the target is a config file, a generated file, or a non-code artifact.

---

## 2. Boundary: what belongs where

| Concern | Belongs in |
|---------|-----------|
| LSP server connection and lifecycle | Adapter |
| Request/response serialisation (JSON-RPC) | Adapter |
| Symbol result interpretation | Core or calling agent |
| Decision of whether to open a file or navigate | Core / calling agent |
| Fallback to text search when LSP unavailable | Adapter (transparent) |

---

## 3. Required output structure

LSP adapter results must be returned as structured envelopes, not raw LSP protocol responses:

**Definition result:**
```json
{
  "status": "success",
  "data": {
    "symbol": "create_project_structure",
    "kind": "function",
    "location": { "file": "src/core/project.py", "line": 42, "character": 4 },
    "preview": "def create_project_structure(root: Path, config: Config) -> Result:"
  },
  "trace_id": "lsp_def_abc123",
  "evidence": [{ "type": "lsp_server", "value": "pylsp@1.9.0" }]
}
```

**References result:**
```json
{
  "status": "success",
  "data": {
    "symbol": "create_project_structure",
    "references": [
      { "file": "src/cli/adapter.py", "line": 88, "context": "result = create_project_structure(root, cfg)" },
      { "file": "tests/test_core.py",  "line": 14, "context": "create_project_structure(tmp_path, default_cfg)" }
    ],
    "total": 2
  },
  "trace_id": "lsp_ref_abc123"
}
```

---

## 4. Anti-patterns

**Broad grep for a symbol that has a definition**

```bash
# WRONG — opens every file that mentions the name
grep -r "create_project_structure" .
```

Fix: use `textDocument/definition` first. Only fall back to grep when the LSP definition returns zero results or the server is unavailable.

**Manual call-chain tracing by opening files sequentially**

```
open file A → find function → open file B → find caller → open file C ...
```

Fix: use `textDocument/references` once to get all call sites. Navigate directly to the relevant locations rather than reading file by file.

---

## 5. Rename as a mutation

Renaming a symbol via LSP is a `local_mutation` operation. Before applying:
1. Run `workspace/rename` with `dry_run: true` (or inspect `WorkspaceEdit` without applying).
2. Review the list of affected files and line numbers.
3. Apply only after review confirms no unintended matches.
4. Run tests or diagnostics after applying.

Record the rename in the commit message with before/after symbol names. If the symbol is part of a public API or MCP tool schema, treat it as a migration (alias + deprecation note + version bump).
