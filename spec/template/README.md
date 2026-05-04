# Template Spec Example

This directory shows the optional `rtl_buddy` spec traceability flow for the starter `template_top` block.

- `specs.yaml` defines the block and its coverage items.
- `design/template/models.yaml` links the design model to this spec with `spec:`.
- `verif/template/tests.yaml` links runnable tests back to the coverage items with `covers:`.

From the repo root you can inspect the linkage with:

```bash
uv run rb spec list
uv run rb spec check-design
uv run rb spec check-coverage
```
