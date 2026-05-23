# The Art of Naming

Names are execution hints. Agents use them to decide what to open, call, combine, or ignore.

## 1. Start with intent

Ask what the caller wants to accomplish.

- `inspect` means look without changing.
- `diagnose` means inspect, rank likely causes, and return next actions.
- `prepare` means stage without applying.
- `apply` means mutate.
- `replay` means reproduce a prior path.
- `verify` means check evidence against a contract.

Do not use a stronger verb than the tool actually performs.

## 2. Separate user-facing and agent-facing names

User-facing names may be natural and tolerant of synonyms. Agent-facing names should be precise, stable, and low ambiguity.

| User might say | Agent-facing name |
|---|---|
| “check what broke” | `diagnose_recent_failure` |
| “show me the important files” | `find_and_outline` |
| “make the edit safely” | `prepare_patch` then `apply_patch` |
| “continue this task” | `resume_task` |

## 3. Name by outcome, not backend

Bad names expose topology: `github_api_call`, `mcp_search_handler`, `db_processor`.

Better names expose intent: `list_open_issues`, `find_relevant_files`, `summarize_run_artifacts`.

## 4. Run the inferability test

Given only the name, can a new agent infer:

- whether it reads or mutates;
- what object it acts on;
- whether it is broad or narrow;
- what output shape is likely;
- whether it needs approval?

If not, rename.

## 5. Avoid vague nouns

Avoid `manager`, `helper`, `util`, `runner`, `processor`, `handler`, and `service` unless qualified.

Acceptable: `task_session_manager` if it really owns task session lifecycle. Weak: `file_helper`.

## 6. Preserve names during mechanical porting

During mechanical porting, preserve source names unless blocked by syntax, reserved words, or public API requirements. After the port passes tests, adapter-facing names may be wrapped with UBAP-compliant names while original internal names remain traceable.

## 7. Rename as migration

Renaming a public tool, command, schema, or resource path is a migration. Provide alias, deprecation note, version bump, and recipe update when the artifact is already used by agents.
