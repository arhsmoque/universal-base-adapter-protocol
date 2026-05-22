# Spec Packet

Use this when new base logic is needed or when a mechanical port/extraction changes behavior.

```yaml
spec:
  component: ""
  intent: ""
  surface: "base | cli | web | api | mcp | worker | skill | docs | lsp | sandbox"
  risk_class: "read_only | local_mutation | external_mutation | destructive | open_world"
  input_contract: {}
  output_contract: {}
  error_cases:
    - code: ""
      condition: ""
      recoverable: true
      next_action_hint: ""
  example_traces:
    - name: "happy path"
      input: {}
      output: {}
  invariants: []
  budget:
    max_tokens: null
    max_pages: null
    max_bytes: null
    max_cost_usd: null
  verification:
    smoke: ""
    failure: ""
    contract: ""
    mutation_dry_run: ""
    replay: ""
```
